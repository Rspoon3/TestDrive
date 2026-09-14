//
//  PlaylistsViewModel.swift
//  TestDrive
//

import MediaPlayer
import MusicKit
import Observation

/// Loads the playlists in the listener's Apple Music library.
@Observable
final class PlaylistsViewModel {

    /// What the playlist list should be showing.
    enum State: Equatable {
        case loading
        case unauthorized
        case loaded([Playlist])
        case failed(String)
    }

    private(set) var state: State = .loading

    // MARK: - Public Helpers

    /// Requests music access and loads every playlist in the library.
    func load() async {
        state = .loading

        guard await MusicAuthorization.request() == .authorized else {
            state = .unauthorized
            return
        }

        // Needed so `TrackAudioResolver` can look for unprotected local files.
        await requestMediaLibraryAccess()

        do {
            let response = try await MusicLibraryRequest<Playlist>().response()
            state = .loaded(
                response.items.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    /// Asks for local media library access, which gates `MPMediaItem.assetURL`.
    private func requestMediaLibraryAccess() async {
        guard MPMediaLibrary.authorizationStatus() == .notDetermined else { return }

        await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
