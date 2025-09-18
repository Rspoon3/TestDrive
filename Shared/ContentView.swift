//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = PhotoRankingViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isPickerPresented = false
    @State private var showDocumentPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.selectedPhotos.isEmpty {
                    // Initial state - show photo picker
                    VStack(spacing: 30) {
                        Image(systemName: "photo.stack")
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
                                Label("Select from Photos", systemImage: "photo.on.rectangle.angled")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .onChange(of: selectedItems) { _, newItems in
                                Task {
                                    await viewModel.loadPhotos(from: newItems)
                                }
                            }

                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                Label("Select from Files", systemImage: "folder")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
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
                            Button(action: {
                                viewModel.selectedPhotos = []
                                selectedItems = []
                            }) {
                                Label("New Ranking", systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            ShareLink(
                                item: createShareText(),
                                subject: Text("Photo Ranking Results")
                            ) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
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
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(completion: { urls in
                Task {
                    await viewModel.loadPhotosFromFiles(urls: urls)
                }
            })
        }
    }

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
