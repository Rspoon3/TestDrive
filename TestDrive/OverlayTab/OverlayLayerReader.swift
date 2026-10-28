//
//  OverlayLayerReader.swift
//  TestDrive
//

import SwiftUI

/// Reads whether the primary view of an overlay arrangement is layered above the secondary.
///
/// The system only publishes the layer to views inside the arrangement, so use this in the primary closure.
struct OverlayLayerReader<Content: View>: View {
    @Environment(\.overlayArrangementZIndex) private var zIndex
    private let content: (_ isLayered: Bool) -> Content
    
    // MARK: - Initializer
    
    /// - Parameter content: Builds the content, told whether it is layered above the secondary (`true`)
    ///   or separated from it around a partial fold (`false`).
    init(@ViewBuilder content: @escaping (_ isLayered: Bool) -> Content) {
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        content(zIndex > 0)
    }
}
