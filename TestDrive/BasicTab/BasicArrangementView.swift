//
//  BasicArrangementView.swift
//  TestDrive
//

import SwiftUI

/// A bare `ArrangementView` with the default style, to see how it behaves on its own.
struct BasicArrangementView: View {
    // MARK: - Body
    
    var body: some View {
        ArrangementView {
            ScrollView {
                Text(Self.copy)
                    .padding()
            }
        } secondary: {
            Color.indigo
        }
    }
    
    // MARK: - Private Helpers
    
    private static let copy = String(
        repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ",
        count: 20
    )
}

#Preview {
    BasicArrangementView()
}
