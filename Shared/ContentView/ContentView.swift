//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SFSymbols

/// Main view for the photo ranking application.
struct ContentView: View {
    @StateObject private var viewModel = PhotoRankingViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isPickerPresented = false
    @State private var showDocumentPicker = false
    @State private var showSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .initial:
                    InitialView(
                        selectedItems: $selectedItems,
                        onPhotosSelected: { items in
                            await viewModel.loadPhotos(from: items)
                        },
                        onShowDocumentPicker: {
                            showDocumentPicker = true
                        }
                    )
                case .loading:
                    loadingView
                case .comparing(let left, let right, let progress, let canUndo):
                    PhotoComparisonView(
                        leftPhoto: left,
                        rightPhoto: right,
                        onSelection: { isLeft in
                            viewModel.selectPhoto(isLeft: isLeft)
                        },
                        onUndo: {
                            viewModel.undoLastComparison()
                        },
                        canUndo: canUndo,
                        progress: progress
                    )
                case .complete(let photos):
                    completionView(photos: photos)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if case .initial = viewModel.viewState {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(symbol: .gearshape)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(completion: { urls in
                Task {
                    await viewModel.loadPhotosFromFiles(urls: urls)
                }
            })
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Private Views

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Preparing photos...")
                .padding(.top)
                .foregroundColor(.secondary)
        }
    }

    private func completionView(photos: [PhotoItem]) -> some View {
        VStack {
            RankedPhotosListView(photos: photos)

            HStack(spacing: 20) {
                Button {
                    viewModel.reset()
                    selectedItems = []
                } label: {
                    HStack {
                        Image(symbol: .arrowClockwise)
                            .foregroundColor(.white)
                        Text("New Ranking")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }

                ShareLink(
                    item: createShareText(photos: photos),
                    subject: Text("Photo Ranking Results")
                ) {
                    HStack {
                        Image(symbol: .squareAndArrowUp)
                            .foregroundColor(.white)
                        Text("Share")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Private Helpers

    private func createShareText(photos: [PhotoItem]) -> String {
        var text = "My Photo Rankings:\n\n"
        for (index, photo) in photos.enumerated() {
            text += "\(index + 1). \(photo.filename)\n"
        }
        return text
    }
}

#Preview {
    ContentView()
}
