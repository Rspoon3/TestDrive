//
//  StackedScrollSampleView.swift
//  TestDrive
//

import SwiftUI

/// A `.split` arrangement that moves the color into the scroll view on the closed outer display.
///
/// - Open or book pose: the text scrolls on the left and the color is on the right.
/// - Laptop pose: the text scrolls on top and the color is on the bottom.
/// - Closed: one scroll view with the text and the color at the bottom.
///
/// The closed outer display and laptop pose would both stack the views vertically, so the width size class
/// tells them apart: the outer display is compact, the inner display is regular. When compact, the split is
/// limited to horizontal, which the outer display can't fit, so only the primary is shown and it holds the color.
struct StackedScrollSampleView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    /// Compact (closed) can only split side by side, which it can't fit, so the primary is shown alone.
    private var allowedAxes: Axis.Set {
        isCompact ? .horizontal : [.horizontal, .vertical]
    }
    
    // MARK: - Body
    
    var body: some View {
        ArrangementView {
            Primary()
        } secondary: {
            ColorPanel()
                .padding()
        }
        .arrangementViewStyle(.split.axes(allowedAxes))
    }
    
    // MARK: - Private Views
    
    private func Primary() -> some View {
        ScrollView {
            Text(Self.copy)
                .padding()
            
            if isCompact {
                ColorPanel()
                    .frame(height: 300)
                    .padding()
            }
        }
    }
    
    private func ColorPanel() -> some View {
        Color.orange
            .clipShape(.rect(cornerRadius: 12))
    }
    
    // MARK: - Private Helpers
    
    private static let copy = String(
        repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ",
        count: 20
    )
}

#Preview {
    StackedScrollSampleView()
}
