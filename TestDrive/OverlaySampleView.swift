//
//  OverlaySampleView.swift
//  TestDrive
//

import SwiftUI

/// Sample of the iPhone Duo layout using an overlay arrangement.
///
/// - Flat, closed, and on regular iPhones and iPads: one scroll view with the text and the color at the bottom.
/// - Partially folded: the system separates the two. The text scrolls on its side of the fold
///   and the color takes the other side.
///
/// ## Why overlay?
/// Nothing here is meant to visibly overlap. Overlay is used because it is the only style that separates
/// the two views *only* around a partial fold. `.split` also splits side by side when the Duo is fully open,
/// and `splitArrangementAxis` reports `horizontal` for both flat and book pose, so it can't tell them apart.
///
/// ## Which view is on top?
/// The **primary** is the layered view that sits on top, and the **secondary** is the backdrop behind it.
/// While layered, the primary holds everything, color included, so the secondary must stay empty or it
/// would show through behind the scroll view. The primary reads `overlayArrangementZIndex` (1 while layered,
/// 0 once separated) and tells the secondary through `isSeparated`.
struct OverlaySampleView: View {
    /// The secondary is always built, so it must stay empty while layered behind the primary.
    @State private var isSeparated = false
    
    // MARK: - Body
    
    var body: some View {
        ArrangementView {
            Primary()
                .overlayArrangementEdge(.leading)
                .overlayArrangementEdge(.top)
        } secondary: {
            Secondary()
                .overlayArrangementEdge(.trailing)
                .overlayArrangementEdge(.bottom)
        }
        .arrangementViewStyle(.overlay)
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func Primary() -> some View {
        OverlayLayerReader { isLayered in
            ScrollView {
                Text(Self.copy)
                    .padding()
                
                if isLayered {
                    ColorPanel()
                        .frame(height: 300)
                        .padding()
                }
            }
            .onChange(of: isLayered, initial: true) {
                isSeparated = !isLayered
            }
        }
    }
    
    @ViewBuilder
    private func Secondary() -> some View {
        if isSeparated {
            ColorPanel()
                .padding()
        }
    }
    
    private func ColorPanel() -> some View {
        Color.teal
            .clipShape(.rect(cornerRadius: 12))
    }
    
    // MARK: - Private Helpers
    
    private static let copy = String(
        repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ",
        count: 20
    )
}

#Preview {
    OverlaySampleView()
}
