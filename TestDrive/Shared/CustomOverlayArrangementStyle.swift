//
//  CustomOverlayArrangementStyle.swift
//  TestDrive
//

import SwiftUI

/// A custom `ArrangementViewStyle` that mimics the Overlay tab.
///
/// Around a partial fold the views take their own sides. Otherwise only the primary shows, and it reads
/// `isArrangementSeparated` to hold the secondary's content itself.
struct CustomOverlayArrangementStyle: ArrangementViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        FoldArrangementLayout(
            unfolded: .primaryOnly,
            primary: configuration.primary,
            secondary: configuration.secondary
        )
    }
}
