//
//  TempoCache.swift
//  TestDrive
//

import Foundation
import MusicKit
import OSLog

/// Persists measured tempos so a playlist only has to be analyzed once.
///
/// Analysis is CPU bound and preview downloads cost network, so results are written to a small
/// JSON file in the caches directory and reloaded on the next launch.
actor TempoCache {
    static let shared = TempoCache()

    private struct Entry: Codable {
        let bpm: Double
        let source: TempoSource
    }

    private static let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "TempoCache")

    private let fileURL: URL
    private var entries: [String: Entry]?

    // MARK: - Initializer

    /// Creates a cache.
    /// - Parameter fileURL: Where measurements are stored. Defaults to the caches directory.
    init(fileURL: URL = .cachesDirectory.appending(path: "playlist-tempos.json")) {
        self.fileURL = fileURL
    }

    // MARK: - Public Helpers

    /// Reads a previously measured tempo.
    /// - Parameter id: The song's MusicKit identifier.
    /// - Returns: The cached tempo, or `nil` when the song hasn't been analyzed yet.
    func tempo(for id: MusicItemID) -> (bpm: Double, source: TempoSource)? {
        guard let entry = loadedEntries()[id.rawValue] else { return nil }
        return (entry.bpm, entry.source)
    }

    /// Stores a measured tempo.
    /// - Parameters:
    ///   - bpm: The measured tempo.
    ///   - source: Which audio the tempo came from.
    ///   - id: The song's MusicKit identifier.
    func store(bpm: Double, source: TempoSource, for id: MusicItemID) {
        var entries = loadedEntries()
        entries[id.rawValue] = Entry(bpm: bpm, source: source)
        self.entries = entries

        do {
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
        } catch {
            Self.logger.error("Could not write tempo cache: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private Helpers

    /// Reads the cache file on first access and keeps it in memory afterwards.
    /// - Returns: Every cached measurement, keyed by raw song identifier.
    private func loadedEntries() -> [String: Entry] {
        if let entries { return entries }

        let entries = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([String: Entry].self, from: $0) } ?? [:]

        self.entries = entries
        return entries
    }
}
