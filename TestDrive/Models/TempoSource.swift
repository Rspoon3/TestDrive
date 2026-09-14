//
//  TempoSource.swift
//  TestDrive
//

import Foundation

/// Describes which audio a song's tempo was measured from.
///
/// Apple Music streams and downloads are FairPlay protected and can never be analyzed, so a
/// song's tempo comes either from an unprotected file in the listener's own library or from the
/// catalog preview excerpt.
nonisolated enum TempoSource: String, Codable, Sendable {
    /// Measured from the complete, unprotected audio file in the listener's library.
    case fullTrack

    /// Measured from the song's Apple Music catalog preview excerpt.
    case preview

    /// A short label suitable for display alongside a BPM value.
    var displayName: String {
        switch self {
        case .fullTrack: "Full track"
        case .preview: "Preview"
        }
    }
}
