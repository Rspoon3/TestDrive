//
//  CustomStackedSampleView.swift
//  TestDrive
//

import SwiftUI

/// The Stacked tab built with a custom `ArrangementViewStyle` instead of a built-in one.
///
/// - Open or book pose: text scrolls on the left, color on the right.
/// - Laptop pose: text scrolls on top, color on the bottom.
/// - Closed: one scroll view with the text and the color at the bottom.
///
/// The style can't change the primary's content, so it passes `isArrangementSeparated` through the
/// environment and the primary uses it to decide whether to hold the color itself.
struct CustomStackedSampleView: View {
    // MARK: - Body
    
    var body: some View {
        ArrangementView {
            PrimaryContent()
        } secondary: {
            ColorPanel()
                .padding()
        }
        .arrangementViewStyle(CustomSplitArrangementStyle())
    }
    
    // MARK: - Private Views
    
    private struct PrimaryContent: View {
        @Environment(\.isArrangementSeparated) private var isSeparated
        
        var body: some View {
            ScrollView {
                Text(CustomStackedSampleView.copy)
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
            Color.pink
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
    CustomStackedSampleView()
}
