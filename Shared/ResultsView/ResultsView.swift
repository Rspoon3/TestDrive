//
//  ResultsView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// Displays the ranked photos and allows sharing results.
struct ResultsView: View {
    let photos: [PhotoItem]
    let onDismiss: () -> Void
    @State private var trigger: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                RankedPhotosListView(photos: photos)

                Button {
                    trigger = true
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
            .sensoryFeedback(.impact, trigger: trigger)
            .navigationTitle("Final Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(
                        item: createShareText(),
                        subject: Text("Photo Ranking Results")
                    ) {
                        Image(symbol: .squareAndArrowUp)
                    }
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func createShareText() -> String {
        var text = "My Photo Rankings:\n\n"
        for (index, photo) in photos.enumerated() {
            text += "\(index + 1). \(photo.filename)\n"
        }
        return text
    }
}

#Preview {
    ResultsView(
        photos: [],
        onDismiss: {}
    )
}
