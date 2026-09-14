//
//  PlaylistTempoViewModel.swift
//  TestDrive
//

import Foundation
import MusicKit
import MusicUnderstanding
import Observation
import OSLog

/// Loads a playlist's songs, measures each one's tempo, and keeps the fastest at the top.
@Observable
final class PlaylistTempoViewModel {
    let playlist: Playlist

    private(set) var tracks: [TempoTrack] = []
    private(set) var isLoadingTracks = true
    private(set) var errorMessage: String?

    private let analyzer: TempoAnalyzer
    private let audioResolver: TrackAudioResolver
    private let cache: TempoCache

    /// Analysis is CPU bound, so only a few songs are processed at a time.
    private static let maximumConcurrentAnalyses = 3

    nonisolated private static let logger = Logger(
        subsystem: "com.rspoon3.TestDrive",
        category: "PlaylistTempo"
    )

    // MARK: - Initializer

    /// Creates a view model for a playlist.
    /// - Parameters:
    ///   - playlist: The playlist to rank by tempo.
    ///   - analyzer: Measures tempo via Music Understanding.
    ///   - audioResolver: Finds decodable audio for each song.
    ///   - cache: Stores measurements between launches.
    init(
        playlist: Playlist,
        analyzer: TempoAnalyzer = TempoAnalyzer(),
        audioResolver: TrackAudioResolver = TrackAudioResolver(),
        cache: TempoCache = .shared
    ) {
        self.playlist = playlist
        self.analyzer = analyzer
        self.audioResolver = audioResolver
        self.cache = cache
    }

    // MARK: - Public Helpers

    /// How many songs currently have a measured tempo.
    var measuredCount: Int {
        tracks.count { $0.tempoState.bpm != nil }
    }

    /// Whether any song is still queued or being analyzed.
    var isAnalyzing: Bool {
        tracks.contains { $0.tempoState.isInProgress }
    }

    /// Loads the playlist's songs, seeds known tempos from the cache, then analyzes the rest.
    func load() async {
        isLoadingTracks = true
        errorMessage = nil

        do {
            let detailedPlaylist = try await playlist.with([.tracks], preferredSource: .library)
            var tempoTracks = detailedPlaylist.tracks?.map(TempoTrack.init(track:)) ?? []

            for index in tempoTracks.indices {
                guard let cached = await cache.tempo(for: tempoTracks[index].id) else { continue }
                tempoTracks[index].tempoState = .measured(bpm: cached.bpm, source: cached.source)
            }

            tracks = TempoTrack.sortedByDescendingTempo(tempoTracks)
            isLoadingTracks = false

            await analyzePendingTracks()
        } catch {
            errorMessage = error.localizedDescription
            isLoadingTracks = false
        }
    }

    // MARK: - Private Helpers

    /// Analyzes every song that has no tempo yet, a few at a time, re-ranking as results land.
    private func analyzePendingTracks() async {
        let pending = tracks.filter { $0.tempoState == .pending }
        guard !pending.isEmpty else { return }

        let analyzer = analyzer
        let audioResolver = audioResolver
        let cache = cache

        await withTaskGroup(of: (MusicItemID, TempoState).self) { group in
            var iterator = pending.makeIterator()

            for _ in 0 ..< Self.maximumConcurrentAnalyses {
                guard let track = iterator.next() else { break }

                markAnalyzing(track.id)
                group.addTask {
                    let state = await Self.measureTempo(
                        for: track,
                        analyzer: analyzer,
                        audioResolver: audioResolver,
                        cache: cache
                    )
                    return (track.id, state)
                }
            }

            while let (id, state) = await group.next() {
                apply(state, to: id)

                guard let track = iterator.next() else { continue }

                markAnalyzing(track.id)
                group.addTask {
                    let state = await Self.measureTempo(
                        for: track,
                        analyzer: analyzer,
                        audioResolver: audioResolver,
                        cache: cache
                    )
                    return (track.id, state)
                }
            }
        }
    }

    /// Resolves audio for a song and measures its tempo, mapping every failure onto a state.
    /// - Parameters:
    ///   - track: The song to measure.
    ///   - analyzer: Measures tempo via Music Understanding.
    ///   - audioResolver: Finds decodable audio.
    ///   - cache: Stores the measurement on success.
    /// - Returns: The resulting tempo state. This never throws so one bad song can't stop the rest.
    nonisolated private static func measureTempo(
        for track: TempoTrack,
        analyzer: TempoAnalyzer,
        audioResolver: TrackAudioResolver,
        cache: TempoCache
    ) async -> TempoState {
        do {
            let audio = try await audioResolver.audio(for: track)

            defer {
                if audio.isTemporary {
                    try? FileManager.default.removeItem(at: audio.url)
                }
            }

            let bpm = try await analyzer.beatsPerMinute(ofFileAt: audio.url)
            await cache.store(bpm: bpm, source: audio.source, for: track.id)
            return .measured(bpm: bpm, source: audio.source)
        } catch TempoAnalysisError.noAudioAvailable {
            return .unavailable(.noAudioAvailable)
        } catch TempoAnalysisError.noTempoDetected {
            return .unavailable(.noTempoDetected)
        } catch MusicUnderstandingError.hasProtectedContent {
            return .unavailable(.protectedContent)
        } catch {
            logger.error("Tempo analysis failed for \(track.title, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return .unavailable(.failed(error.localizedDescription))
        }
    }

    /// Flags a song as being analyzed so the row can show a spinner.
    /// - Parameter id: The song's identifier.
    private func markAnalyzing(_ id: MusicItemID) {
        guard let index = tracks.firstIndex(where: { $0.id == id }) else { return }
        tracks[index].tempoState = .analyzing
    }

    /// Stores a finished analysis and re-ranks the list.
    /// - Parameters:
    ///   - state: The resulting tempo state.
    ///   - id: The song's identifier.
    private func apply(_ state: TempoState, to id: MusicItemID) {
        guard let index = tracks.firstIndex(where: { $0.id == id }) else { return }
        tracks[index].tempoState = state
        tracks = TempoTrack.sortedByDescendingTempo(tracks)
    }
}
