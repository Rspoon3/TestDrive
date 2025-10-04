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
        InitialView(
            selectedItems: $selectedItems,
            onPhotosSelected: { items in
                await viewModel.loadPhotos(from: items)
            },
            onShowDocumentPicker: {
                showDocumentPicker = true
            }
        )
//        .sensoryFeedback(.increase, trigger: viewModel.isComparing)
//        .sensoryFeedback(.increase, trigger: showDocumentPicker)
        .fullScreenCover(isPresented: $viewModel.isComparing) {
            PhotoComparisonView(photos: viewModel.selectedPhotos) {
                viewModel.reset()
                selectedItems = []
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { urls in
                Task {
                    await viewModel.loadPhotosFromFiles(urls: urls)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
