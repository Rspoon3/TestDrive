//
//  TempoAnalyzer.swift
//  TestDrive
//

import AVFoundation
import Foundation
import MusicUnderstanding

/// Measures a song's tempo with the on-device Music Understanding framework.
///
/// Introduced in "Meet the Music Understanding framework" (WWDC26, session 253). Only the
/// `.rhythm` analysis type is requested so the framework can skip the five other dimensions.
nonisolated struct TempoAnalyzer {

    // MARK: - Public Helpers

    /// Analyzes an audio file's rhythm and returns its tempo.
    /// - Parameter url: A local file URL containing unprotected audio.
    /// - Returns: The detected tempo in beats per minute.
    /// - Throws: `TempoAnalysisError.noTempoDetected` when fewer than two beats were found, or a
    ///   `MusicUnderstandingError` such as `.hasProtectedContent` for undecodable audio.
    func beatsPerMinute(ofFileAt url: URL) async throws -> Double {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )

        let session = try await MusicUnderstandingSession(asset: asset)
        let result = try await session.analyze(for: [.rhythm])

        guard let beatsPerMinute = result.rhythm?.beatsPerMinute else {
            throw TempoAnalysisError.noTempoDetected
        }

        return Double(beatsPerMinute)
    }
}
