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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.selectedPhotos.isEmpty {
                    // Initial state - show photo picker
                    VStack(spacing: 30) {
                        Image(symbol: .photoStack)
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("Photo Ranker")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Select photos to rank them from best to worst")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 15) {
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: 20,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack {
                                    Image(symbol: .photoOnRectangleAngled)
                                        .foregroundColor(.white)
                                    Text("Select from Photos")
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .onChange(of: selectedItems) { _, newItems in
                                Task {
                                    await viewModel.loadPhotos(from: newItems)
                                }
                            }

                            Button {
                                showDocumentPicker = true
                            } label: {
                                HStack {
                                    Image(symbol: .folder)
                                        .foregroundColor(.white)
                                    Text("Select from Files")
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                } else if let comparison = viewModel.currentComparison {
                    // Ranking in progress - show comparison view
                    PhotoComparisonView(
                        leftPhoto: comparison.left,
                        rightPhoto: comparison.right,
                        onSelection: { isLeft in
                            viewModel.selectPhoto(isLeft: isLeft)
                        },
                        onUndo: {
                            viewModel.undoLastComparison()
                        },
                        canUndo: viewModel.canUndo,
                        progress: Double(viewModel.completedComparisons) / Double(max(viewModel.totalComparisons, 1))
                    )
                } else if viewModel.rankingComplete {
                    // Ranking complete - show results
                    VStack {
                        RankedPhotosListView(photos: viewModel.selectedPhotos)

                        HStack(spacing: 20) {
                            Button {
                                viewModel.selectedPhotos = []
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
                                item: createShareText(),
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
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Preparing photos...")
                            .padding(.top)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarHidden(viewModel.selectedPhotos.isEmpty)
            .toolbar {
                if !viewModel.selectedPhotos.isEmpty && viewModel.rankingComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            // Optional: Add any cleanup or navigation logic
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
    }

    // MARK: - Private Helpers

    private func createShareText() -> String {
        var text = "My Photo Rankings:\n\n"
        for (index, photo) in viewModel.selectedPhotos.enumerated() {
            text += "\(index + 1). \(photo.filename)\n"
        }
        return text
    }
}

#Preview {
    ContentView()
}
