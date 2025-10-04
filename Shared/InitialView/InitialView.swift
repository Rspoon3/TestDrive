//
//  InitialView.swift
//  TestDrive
//

import SwiftUI
import PhotosUI
import SFSymbols

/// Initial view for selecting photos to rank.
struct InitialView: View {
    @Binding var selectedItems: [PhotosPickerItem]
    let onPhotosSelected: ([PhotosPickerItem]) async -> Void
    let onShowDocumentPicker: () -> Void

    // MARK: - Body

    var body: some View {
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
                        await onPhotosSelected(newItems)
                    }
                }

                Button {
                    onShowDocumentPicker()
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
    }
}

#Preview {
    InitialView(
        selectedItems: .constant([]),
        onPhotosSelected: { _ in },
        onShowDocumentPicker: { }
    )
}
