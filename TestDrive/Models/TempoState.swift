//
//  TempoState.swift
//  TestDrive
//

import Foundation

/// The tempo analysis lifecycle for a single song.
nonisolated enum TempoState: Equatable, Sendable {
    /// Queued, but analysis hasn't started.
    case pending

    /// Audio is being fetched and analyzed right now.
    case analyzing

    /// A tempo was measured successfully.
    case measured(bpm: Double, source: TempoSource)

    /// No tempo could be produced for this song.
    case unavailable(UnavailableReason)

    /// Explains why a song has no BPM.
    enum UnavailableReason: Equatable, Sendable {
        /// The only audio available is FairPlay protected, which Music Understanding refuses to decode.
        case protectedContent

        /// The song has neither an unprotected library file nor a catalog preview.
        case noAudioAvailable

        /// Music Understanding decoded the audio but found fewer than two beats.
        case noTempoDetected

        /// Something else went wrong, such as a failed preview download.
        case failed(String)

        /// A short, user-facing explanation.
        var message: String {
            switch self {
            case .protectedContent: "Protected audio"
            case .noAudioAvailable: "No audio to analyze"
            case .noTempoDetected: "No steady beat"
            case .failed(let description): description
            }
        }
    }

    /// The measured tempo, or `nil` when analysis hasn't produced a value.
    var bpm: Double? {
        guard case .measured(let bpm, _) = self else { return nil }
        return bpm
    }

    /// Whether analysis is queued or running for this song.
    var isInProgress: Bool {
        switch self {
        case .pending, .analyzing: true
        case .measured, .unavailable: false
        }
    }
}
