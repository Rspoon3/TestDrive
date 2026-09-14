//
//  PlaylistsView.swift
//  TestDrive
//

import MusicKit
import SFSymbols
import SwiftUI

/// Lists the listener's Apple Music playlists so one can be ranked by tempo.
struct PlaylistsView: View {
    @State private var viewModel = PlaylistsViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Playlists")
        }
        .task { await viewModel.load() }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading playlists…")

        case .unauthorized:
            ContentUnavailableView(
                "Apple Music Access Needed",
                symbol: .musicNote,
                description: Text("Allow access in Settings so TestDrive can read your playlists.")
            )

        case .failed(let message):
            ContentUnavailableView(
                "Couldn't Load Playlists",
                symbol: .exclamationmarkTriangle,
                description: Text(message)
            )

        case .loaded(let playlists) where playlists.isEmpty:
            ContentUnavailableView(
                "No Playlists",
                symbol: .musicNoteList,
                description: Text("Create a playlist in Apple Music to rank it by tempo.")
            )

        case .loaded(let playlists):
            List(playlists) { playlist in
                NavigationLink {
                    PlaylistTempoView(playlist: playlist)
                } label: {
                    PlaylistRow(playlist: playlist)
                }
            }
            .refreshable { await viewModel.load() }
        }
    }

    private func PlaylistRow(playlist: Playlist) -> some View {
        HStack(spacing: 12) {
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 48)
                    .clipShape(.rect(cornerRadius: 6))
            } else {
                Image(symbol: .musicNoteList)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, height: 48)
                    .background(.quaternary, in: .rect(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .lineLimit(1)

                if let curatorName = playlist.curatorName {
                    Text(curatorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PlaylistsView()
}
