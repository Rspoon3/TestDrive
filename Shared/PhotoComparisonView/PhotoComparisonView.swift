//
//  PhotoComparisonView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// Displays two photos side by side for comparison and selection.
///
/// This view presents pairs of photos and allows the user to select their preferred image.
/// The layout can be toggled between horizontal and vertical orientations, with the preference
/// persisted across app launches.
///
/// ## Layout Preference
/// The `isVerticalLayout` property uses `@State` with manual UserDefaults persistence instead of
/// `@AppStorage` to ensure smooth matched geometry effect animations when toggling between layouts.
/// `@AppStorage` can interfere with SwiftUI's animation system for matched geometry effects.
struct PhotoComparisonView: View {
    @StateObject private var viewModel: PhotoComparisonViewModel

    /// Controls the layout orientation (vertical vs horizontal).
    /// Uses `@State` instead of `@AppStorage` to preserve matched geometry effect animations.
    @State private var isVerticalLayout = false

    @Namespace private var photoAnimation
    @Environment(\.dismiss) private var dismiss

    let onDismiss: () -> Void

    /// UserDefaults key for persisting the layout preference.
    private let layoutPreferenceKey = "PhotoComparisonVerticalLayout"

    /// Spacing between photos in both vertical and horizontal layouts.
    private let photoSpacing: CGFloat = 20

    // MARK: - Initializer

    init(photos: [PhotoItem], onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: PhotoComparisonViewModel(photos: photos))
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            contentView
                .sensoryFeedback(.increase, trigger: viewModel.progress)
                .sensoryFeedback(.increase, trigger: isVerticalLayout)
                .navigationTitle("Which One?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewModel.canUndo {
                            Button {
                                withAnimation {
                                    viewModel.undoLastComparison()
                                }
                            } label: {
                                Image(symbol: .arrowUturnBackward)
                            }
                            .transition(.opacity)
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isVerticalLayout.toggle()
                                UserDefaults.standard.set(isVerticalLayout, forKey: layoutPreferenceKey)
                            }
                        } label: {
                            Image(symbol: .rectangleSplit1x2)
                                .rotationEffect(.degrees(isVerticalLayout ? 90 : 0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVerticalLayout)
                        }
                    }
                }
                .onAppear {
                    isVerticalLayout = UserDefaults.standard.bool(forKey: layoutPreferenceKey)
                }
        }
        .fullScreenCover(isPresented: $viewModel.rankingComplete) {
            ResultsView(photos: viewModel.rankedPhotos) {
                onDismiss()
                dismiss()
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var contentView: some View {
        if let comparison = viewModel.currentComparison {
            comparisonView(comparison)
        } else {
            ProgressView()
        }
    }

    private func comparisonView(_ comparison: (left: PhotoItem, right: PhotoItem)) -> some View {
        VStack(spacing: 20) {
            // Progress indicator
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .animation(.easeInOut, value: viewModel.progress)

                Text("\(viewModel.progress.formatted(.percent.precision(.fractionLength(0)))) Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: viewModel.progress)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            if isVerticalLayout {
                // Vertical layout
                VStack(spacing: photoSpacing) {
                    photoCard(photo: comparison.left, isLeft: true)
                    photoCard(photo: comparison.right, isLeft: false)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            } else {
                // Horizontal layout
                HStack(spacing: photoSpacing) {
                    photoCard(photo: comparison.left, isLeft: true)
                    photoCard(photo: comparison.right, isLeft: false)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private func photoCard(photo: PhotoItem, isLeft: Bool) -> some View {
        Image(uiImage: photo.image)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .matchedGeometryEffect(id: isLeft ? "leftPhoto" : "rightPhoto", in: photoAnimation)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.selectPhoto(isLeft: isLeft)
                }
            }
    }
}
