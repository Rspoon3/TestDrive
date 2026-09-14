//
//  TrackAudioResolver.swift
//  TestDrive
//

import AVFoundation
import Foundation
import MediaPlayer
import MusicKit

/// Finds audio that the Music Understanding framework is actually able to decode for a song.
///
/// Apple Music streams and downloads are FairPlay protected, so they can never be analyzed. This
/// resolver prefers an unprotected file from the listener's own library — an imported or purchased
/// song — and otherwise downloads the song's catalog preview excerpt.
nonisolated struct TrackAudioResolver {
    private let urlSession: URLSession

    // MARK: - Initializer

    /// Creates a resolver.
    /// - Parameter urlSession: The session used to download preview excerpts.
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Public Helpers

    /// Resolves decodable audio for a song.
    /// - Parameter track: The song to find audio for.
    /// - Returns: A local file containing unprotected audio.
    /// - Throws: `TempoAnalysisError.noAudioAvailable` when the song has no unprotected library
    ///   file and no preview excerpt.
    func audio(for track: TempoTrack) async throws -> TrackAudio {
        if let localURL = localAssetURL(for: track), await isDecodable(localURL) {
            return TrackAudio(url: localURL, source: .fullTrack, isTemporary: false)
        }

        guard let previewURL = track.previewURL else {
            throw TempoAnalysisError.noAudioAvailable
        }

        let downloadedURL = try await downloadToTemporaryFile(previewURL)
        return TrackAudio(url: downloadedURL, source: .preview, isTemporary: true)
    }

    // MARK: - Private Helpers

    /// Looks for an unprotected file in the listener's local media library.
    ///
    /// `MPMediaItem.assetURL` is `nil` for anything FairPlay protected, which is every song that
    /// came from an Apple Music subscription.
    /// - Parameter track: The song to match.
    /// - Returns: A file URL, or `nil` when the song isn't backed by a local unprotected file.
    private func localAssetURL(for track: TempoTrack) -> URL? {
        guard MPMediaLibrary.authorizationStatus() == .authorized else { return nil }

        let query = MPMediaQuery.songs()
        query.addFilterPredicate(
            MPMediaPropertyPredicate(
                value: track.title,
                forProperty: MPMediaItemPropertyTitle,
                comparisonType: .equalTo
            )
        )

        return query.items?
            .first { $0.artist == track.artistName && $0.assetURL != nil }?
            .assetURL
    }

    /// Confirms an asset isn't FairPlay protected before handing it to Music Understanding.
    /// - Parameter url: The file to inspect.
    /// - Returns: `true` when the asset carries no protected content.
    private func isDecodable(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        let hasProtectedContent = try? await asset.load(.hasProtectedContent)
        return hasProtectedContent == false
    }

    /// Downloads a preview excerpt to a temporary file.
    ///
    /// The framework reads through `AVAssetReader`, so a stable local file is far more reliable
    /// than pointing it at a remote URL.
    /// - Parameter url: The remote preview URL.
    /// - Returns: The temporary file the preview was written to.
    private func downloadToTemporaryFile(_ url: URL) async throws -> URL {
        let (temporaryURL, _) = try await urlSession.download(from: url)

        let pathExtension = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(pathExtension)

        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }
}
