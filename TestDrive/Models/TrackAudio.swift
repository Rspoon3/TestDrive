//
//  TrackAudio.swift
//  TestDrive
//

import Foundation

/// A local audio file that the Music Understanding framework is able to decode.
nonisolated struct TrackAudio: Sendable {
    /// A file URL pointing at unprotected audio.
    let url: URL

    /// Which portion of the song `url` represents.
    let source: TempoSource

    /// Whether `url` was written to a temporary location and should be removed after analysis.
    let isTemporary: Bool
}
