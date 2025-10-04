//
//  PhotoComparisonView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// Displays two photos side by side for comparison and selection.
struct PhotoComparisonView: View {
    let leftPhoto: PhotoItem
    let rightPhoto: PhotoItem
    let onSelection: (Bool) -> Void
    let onUndo: () -> Void
    let canUndo: Bool
    let progress: Double

    @State private var isVerticalLayout = false
    @AppStorage("photoSpacing") private var photoSpacing: Double = 20
    @Namespace private var photoAnimation

    private let layoutPreferenceKey = "PhotoComparisonVerticalLayout"

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)

                Text("\(progress.formatted(.percent.precision(.fractionLength(0)))) Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            Text("Which photo do you prefer?")
                .font(.title2)
                .fontWeight(.semibold)

            if isVerticalLayout {
                // Vertical layout
                VStack(spacing: photoSpacing) {
                    photoCard(photo: leftPhoto, isLeft: true)
                    photoCard(photo: rightPhoto, isLeft: false)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            } else {
                // Horizontal layout
                HStack(spacing: photoSpacing) {
                    photoCard(photo: leftPhoto, isLeft: true)
                    photoCard(photo: rightPhoto, isLeft: false)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.vertical)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if canUndo {
                    Button {
                        onUndo()
                    } label: {
                        Image(symbol: .arrowUturnBackward)
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVerticalLayout.toggle()
                        UserDefaults.standard.set(isVerticalLayout, forKey: layoutPreferenceKey)
                    }
                } label: {
                    Image(symbol: isVerticalLayout ? .rectanglePortraitSplit2x1 : .rectangleSplit1x2)
                }
            }
        }
        .onAppear {
            isVerticalLayout = UserDefaults.standard.bool(forKey: layoutPreferenceKey)
        }
    }

    // MARK: - Private Views

    private func photoCard(photo: PhotoItem, isLeft: Bool) -> some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .matchedGeometryEffect(id: isLeft ? "leftPhoto" : "rightPhoto", in: photoAnimation)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    onSelection(isLeft)
                }
            }
    }
}
