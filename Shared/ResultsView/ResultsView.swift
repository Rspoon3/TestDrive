//
//  ResultsView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// Displays the ranked photos and allows sharing results.
struct ResultsView: View {
    @Environment(\.colorScheme) var colorScheme
    let photos: [PhotoItem]
    let onDismiss: () -> Void
    @State private var trigger: UUID = .init()
    @State private var errorTrigger: UUID = .init()
    @State private var showShareSheet = false
    @State private var compositeImage: IdentafiableItem<UIImage>?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                RankedPhotosListView(photos: photos)

                Button {
                    trigger = .init()
                    onDismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .sensoryFeedback(.error, trigger: errorTrigger)
            .sensoryFeedback(.impact, trigger: trigger)
            .navigationTitle("Final Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        guard let image = createCompositeImage() else {
                            errorTrigger = .init()
                            return
                        }
                        
                        trigger = .init()
                        compositeImage = IdentafiableItem(item: image)
                        showShareSheet = true
                    } label: {
                        Image(symbol: .squareAndArrowUp)
                    }
                }
            }
            .sheet(item: $compositeImage) { image in
                ShareSheet(items: [image.item])
            }
        }
    }

    // MARK: - Private Helpers

    /// Creates a composite image from the RankedPhotosListView.
    /// - Returns: A rendered image of the ranked photos list, or nil if creation fails.
    ///
    /// Need to use colorScheme because `systemBackground` never shows in black
    /// for some reason. I think it's a bug with `ImageRenderer`.
    @MainActor
    private func createCompositeImage() -> UIImage? {
        let view = RankedPhotosListView(
            photos: photos,
            useScrollView: false
        ).background(Color(colorScheme == .light ? .white : .black))
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .blue
        }
    }

    private func rankTitle(for index: Int) -> String {
        switch index {
        case 0: return "🥇 Best Photo"
        case 1: return "🥈 Second Place"
        case 2: return "🥉 Third Place"
        default: return "Rank \(index + 1)"
        }
    }
}

#Preview {
    ResultsView(
        photos: [],
        onDismiss: {}
    )
}
