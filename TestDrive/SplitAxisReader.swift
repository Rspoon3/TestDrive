//
//  SplitAxisReader.swift
//  TestDrive
//

import SwiftUI

/// Reads the axis a split arrangement is using, from inside the arrangement.
struct SplitAxisReader<Content: View>: View {
    @Environment(\.splitArrangementAxis) private var splitAxis
    private let content: (_ axis: Axis?) -> Content
    
    // MARK: - Initializer
    
    /// - Parameter content: Builds the content, told the split axis, or `nil` when not split.
    init(@ViewBuilder content: @escaping (_ axis: Axis?) -> Content) {
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        content(splitAxis)
    }
}
