//
//  PlaylistTempoView.swift
//  TestDrive
//

import MusicKit
import SFSymbols
import SwiftUI

/// Shows a playlist's songs ranked by tempo, fastest first.
struct PlaylistTempoView: View {
    @State private var viewModel: PlaylistTempoViewModel

    // MARK: - Initializer

    /// Creates a tempo ranking for a playlist.
    /// - Parameter playlist: The playlist to rank.
    init(playlist: Playlist) {
        _viewModel = State(initialValue: PlaylistTempoViewModel(playlist: playlist))
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle(viewModel.playlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingTracks {
            ProgressView("Loading songs…")
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView(
                "Couldn't Load Songs",
                symbol: .exclamationmarkTriangle,
                description: Text(errorMessage)
            )
        } else if viewModel.tracks.isEmpty {
            ContentUnavailableView(
                "No Songs",
                symbol: .musicNote,
                description: Text("This playlist is empty.")
            )
        } else {
            List {
                Section {
                    ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { index, track in
                        TrackRow(rank: index + 1, track: track)
                    }
                } header: {
                    ProgressHeader()
                }
            }
            .animation(.default, value: viewModel.tracks.map(\.id))
            .refreshable { await viewModel.load() }
        }
    }

    private func ProgressHeader() -> some View {
        HStack(spacing: 8) {
            Label(
                "\(viewModel.measuredCount) of \(viewModel.tracks.count) analyzed",
                symbol: .metronome
            )

            if viewModel.isAnalyzing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func TrackRow(rank: Int, track: TempoTrack) -> some View {
        HStack(spacing: 12) {
            Text(rank.formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            if let artwork = track.artwork {
                ArtworkImage(artwork, width: 44)
                    .clipShape(.rect(cornerRadius: 4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TempoBadge(state: track.tempoState)
        }
    }

    @ViewBuilder
    private func TempoBadge(state: TempoState) -> some View {
        switch state {
        case .pending:
            Image(symbol: .metronome)
                .foregroundStyle(.tertiary)

        case .analyzing:
            ProgressView()
                .controlSize(.small)

        case .measured(let bpm, let source):
            VStack(alignment: .trailing, spacing: 1) {
                Text(bpm.formatted(.number.precision(.fractionLength(0))))
                    .font(.headline.monospacedDigit())

                Text(source == .preview ? "BPM · preview" : "BPM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        case .unavailable(let reason):
            Text(reason.message)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90, alignment: .trailing)
        }
    }
}
