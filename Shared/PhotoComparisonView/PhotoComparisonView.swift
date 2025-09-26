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
    @Namespace private var photoAnimation

    private let layoutPreferenceKey = "PhotoComparisonVerticalLayout"

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator with undo button
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ranking Progress")
                        .font(.headline)

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)

                    Text("\(Int(progress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isVerticalLayout.toggle()
                            UserDefaults.standard.set(isVerticalLayout, forKey: layoutPreferenceKey)
                        }
                    } label: {
                        Image(symbol: isVerticalLayout ? .rectanglePortraitSplit2x1 : .rectangleSplit1x2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }

                    if canUndo {
                        Button {
                            onUndo()
                        } label: {
                            HStack {
                                Image(symbol: .arrowUturnBackward)
                                    .foregroundColor(.white)
                                Text("Undo")
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)

            Text("Which photo do you prefer?")
                .font(.title2)
                .fontWeight(.semibold)

            if isVerticalLayout {
                // Vertical layout
                ScrollView {
                    VStack(spacing: 20) {
                        photoCard(photo: leftPhoto, isLeft: true)
                        photoCard(photo: rightPhoto, isLeft: false)
                    }
                    .padding(.horizontal)
                }
            } else {
                // Horizontal layout
                HStack(spacing: 20) {
                    photoCard(photo: leftPhoto, isLeft: true)
                    photoCard(photo: rightPhoto, isLeft: false)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.vertical)
        .onAppear {
            isVerticalLayout = UserDefaults.standard.bool(forKey: layoutPreferenceKey)
        }
    }

    // MARK: - Private Views

    private func photoCard(photo: PhotoItem, isLeft: Bool) -> some View {
        VStack {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: isVerticalLayout ? 300 : 400)
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

            Button {
                onSelection(isLeft)
            } label: {
                Text("Select This")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .matchedGeometryEffect(id: isLeft ? "leftButton" : "rightButton", in: photoAnimation)
        }
    }
}
