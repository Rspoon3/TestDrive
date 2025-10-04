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
    @State private var showFileImporter = false

    // MARK: - Body

    var body: some View {
        InitialView(
            selectedItems: $selectedItems,
            onPhotosSelected: { items in
                await viewModel.loadPhotos(from: items)
            },
            onShowDocumentPicker: {
                showFileImporter = true
            }
        )
//        .sensoryFeedback(.increase, trigger: viewModel.isComparing)
        .sensoryFeedback(trigger: showFileImporter){ _, newValue in
            newValue ? .increase : nil
        }
        .fullScreenCover(isPresented: $viewModel.isComparing) {
            PhotoComparisonView(photos: viewModel.selectedPhotos) {
                viewModel.reset()
                selectedItems = []
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await viewModel.loadPhotosFromFiles(urls: urls)
                }
            case .failure(let error):
                print("File import error: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView()
}
