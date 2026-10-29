//
//  CustomSplitArrangementStyle.swift
//  TestDrive
//

import SwiftUI

/// A custom `ArrangementViewStyle` that mimics the Stacked tab.
///
/// Around a partial fold the views take their own sides. Otherwise they sit side by side when there is room
/// (regular width and landscape), otherwise only the primary shows, such as flat in portrait or on the closed outer display. The primary reads
/// `isArrangementSeparated` to know whether it needs to hold the secondary's content itself.
struct CustomSplitArrangementStyle: ArrangementViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        FoldArrangementLayout(
            unfolded: .split,
            primary: configuration.primary,
            secondary: configuration.secondary
        )
    }
}
