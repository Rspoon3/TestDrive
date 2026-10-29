//
//  CustomOverlaySampleView.swift
//  TestDrive
//

import SwiftUI

/// The Overlay tab built with a custom `ArrangementViewStyle` instead of a built-in one.
///
/// - Flat, closed, regular iPhones and iPads: one scroll view with the text and the color at the bottom.
/// - Partially folded: text scrolls on its side of the fold, color on the other.
///
/// The style can't change the primary's content, so it passes `isArrangementSeparated` through the
/// environment and the primary uses it to decide whether to hold the color itself.
struct CustomOverlaySampleView: View {
    // MARK: - Body
    
    var body: some View {
        ArrangementView {
            PrimaryContent()
        } secondary: {
            ColorPanel()
                .padding()
        }
        .arrangementViewStyle(CustomOverlayArrangementStyle())
    }
    
    // MARK: - Private Views
    
    private struct PrimaryContent: View {
        @Environment(\.isArrangementSeparated) private var isSeparated
        
        var body: some View {
            ScrollView {
                Text(CustomOverlaySampleView.copy)
                    .padding()
                
                if !isSeparated {
                    ColorPanel()
                        .frame(height: 300)
                        .padding()
                }
            }
        }
    }
    
    private struct ColorPanel: View {
        var body: some View {
            Color.purple
                .clipShape(.rect(cornerRadius: 12))
        }
    }
    
    // MARK: - Private Helpers
    
    fileprivate static let copy = String(
        repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ",
        count: 20
    )
}

#Preview {
    CustomOverlaySampleView()
}
