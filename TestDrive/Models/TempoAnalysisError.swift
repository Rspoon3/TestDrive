//
//  TempoAnalysisError.swift
//  TestDrive
//

import Foundation

/// Errors raised while trying to measure a song's tempo.
nonisolated enum TempoAnalysisError: Error, Equatable {
    /// Nothing decodable could be found for the song — no unprotected library file and no preview.
    case noAudioAvailable

    /// Music Understanding processed the audio but could not settle on a tempo.
    case noTempoDetected
}
