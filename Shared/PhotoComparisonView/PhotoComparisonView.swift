//
//  PhotoComparisonView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// Displays two photos side by side for comparison and selection.
struct PhotoComparisonView: View {
    @StateObject private var viewModel: PhotoComparisonViewModel
    @State private var isVerticalLayout = false
    @Namespace private var photoAnimation
    
    private let layoutPreferenceKey = "PhotoComparisonVerticalLayout"
    private let photoSpacing: CGFloat = 20
    
    // MARK: - Initializer
    
    init(photos: [PhotoItem]) {
        _viewModel = StateObject(wrappedValue: PhotoComparisonViewModel(photos: photos))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            contentView
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewModel.canUndo {
                            Button {
                                viewModel.undoLastComparison()
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
        .sheet(isPresented: $viewModel.rankingComplete) {
            ResultsView(photos: viewModel.rankedPhotos) {
                viewModel.rankingComplete = false
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
                
                Text("\(viewModel.progress.formatted(.percent.precision(.fractionLength(0)))) Complete")
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
