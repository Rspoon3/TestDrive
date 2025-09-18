//
//  PhotoComparisonView.swift
//  TestDrive
//

import SwiftUI

struct PhotoComparisonView: View {
    let leftPhoto: PhotoItem
    let rightPhoto: PhotoItem
    let onSelection: (Bool) -> Void
    let onUndo: () -> Void
    let canUndo: Bool
    let progress: Double

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

                Spacer()

                if canUndo {
                    Button(action: onUndo) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)

            Text("Which photo do you prefer?")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                // Left photo
                VStack {
                    Image(uiImage: leftPhoto.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                onSelection(true)
                            }
                        }

                    Button(action: { onSelection(true) }) {
                        Text("Select This")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                // Right photo
                VStack {
                    Image(uiImage: rightPhoto.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                onSelection(false)
                            }
                        }

                    Button(action: { onSelection(false) }) {
                        Text("Select This")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical)
    }
}