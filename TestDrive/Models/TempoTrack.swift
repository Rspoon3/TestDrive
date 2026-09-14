//
//  TempoTrack.swift
//  TestDrive
//

import Foundation
import MusicKit

/// A playlist song flattened into the values needed to analyze and display its tempo.
///
/// The MusicKit `Track` itself is deliberately not retained so that this type stays trivially
/// constructible in tests and previews.
nonisolated struct TempoTrack: Identifiable, Sendable {
    let id: MusicItemID
    let title: String
    let artistName: String
    let artwork: Artwork?
    let duration: TimeInterval?

    /// The catalog preview excerpt, used when no unprotected library file exists.
    let previewURL: URL?

    /// Where this song currently sits in the analysis lifecycle.
    var tempoState: TempoState

    // MARK: - Initializer

    /// Creates a tempo track from its individual values.
    /// - Parameters:
    ///   - id: The song's MusicKit identifier.
    ///   - title: The song title.
    ///   - artistName: The performing artist.
    ///   - artwork: Optional artwork for the row.
    ///   - duration: The song's length, when known.
    ///   - previewURL: A downloadable preview excerpt, when the song has one.
    ///   - tempoState: The starting analysis state.
    init(
        id: MusicItemID,
        title: String,
        artistName: String,
        artwork: Artwork? = nil,
        duration: TimeInterval? = nil,
        previewURL: URL? = nil,
        tempoState: TempoState = .pending
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artwork = artwork
        self.duration = duration
        self.previewURL = previewURL
        self.tempoState = tempoState
    }

    /// Creates a tempo track from a MusicKit playlist track.
    /// - Parameter track: The track to flatten.
    init(track: Track) {
        self.init(
            id: track.id,
            title: track.title,
            artistName: track.artistName,
            artwork: track.artwork,
            duration: track.duration,
            previewURL: track.previewAssets?.first?.url
        )
    }

    // MARK: - Public Helpers

    /// Orders songs fastest first, keeping songs without a tempo below the ranked ones.
    ///
    /// Measured songs sort by descending BPM, then in-progress songs, then unavailable ones. Ties
    /// fall back to the incoming order so rows don't shuffle while analysis streams in.
    /// - Parameter tracks: The songs to order.
    /// - Returns: The songs sorted by descending tempo.
    static func sortedByDescendingTempo(_ tracks: [TempoTrack]) -> [TempoTrack] {
        tracks
            .enumerated()
            .sorted { lhs, rhs in
                guard lhs.element.sortGroup == rhs.element.sortGroup else {
                    return lhs.element.sortGroup < rhs.element.sortGroup
                }

                if let left = lhs.element.tempoState.bpm,
                   let right = rhs.element.tempoState.bpm,
                   left != right {
                    return left > right
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    // MARK: - Private Helpers

    /// Groups states so measured songs always outrank unmeasured ones.
    private var sortGroup: Int {
        switch tempoState {
        case .measured: 0
        case .pending, .analyzing: 1
        case .unavailable: 2
        }
    }
}
