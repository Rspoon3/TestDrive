//
//  StackedScrollSampleView.swift
//  TestDrive
//

import SwiftUI

/// A `.split` arrangement limited to side by side, with the color moving into the scroll view otherwise.
///
/// - Side by side (open or book pose): the text scrolls on the left and the color is on the right.
/// - Anything else (closed, laptop): the system can't split horizontally, so only the primary is shown.
///   It then holds the color at the bottom of its scroll view.
///
/// The default split also stacks the views vertically when the Duo is fully open, which put the color
/// below the text instead of beside it. Limiting the axes to horizontal avoids that.
struct StackedScrollSampleView: View {
    // MARK: - Body
    
    var body: some View {
        ArrangementView {
            ZStack { Primary() }
        } secondary: {
            ZStack { ColorPanel().padding() }
        }
        .arrangementViewStyle(.split.axes(.horizontal))
    }
    
    // MARK: - Private Views
    
    private func Primary() -> some View {
        SplitAxisReader { axis in
            ScrollView {
                Text("axis: \(String(describing: axis))")
                    .font(.headline)
                
                Text(Self.copy)
                    .padding()
                
                if axis != .horizontal {
                    ColorPanel()
                        .frame(height: 300)
                        .padding()
                }
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
