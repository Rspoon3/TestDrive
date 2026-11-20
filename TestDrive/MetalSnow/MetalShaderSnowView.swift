//
//  MetalShaderSnowView.swift
//  TestDrive
//

import SwiftUI

/// A full-bleed snowfall drawn entirely by a Metal fragment shader through SwiftUI's `colorEffect`.
///
/// There are no particles to update: the `snowfall` shader works out every flake from the pixel's position and the
/// elapsed time, so the work scales with screen pixels and depth layers instead of flake count. The CPU only passes in
/// the time each frame. It takes the same ``SnowfallConfiguration`` as the other snow views and uses the same depth
/// bands as ``SnowLayerStyle``. There is no snow pile and no blizzard haze.
struct MetalShaderSnowView: View {
    private let parameters: [Float]

    @State private var startDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates the snow.
    /// - Parameter configuration: How much snow falls, how fast, and how windy it is.
    init(configuration: SnowfallConfiguration = .default) {
        parameters = SnowShaderParameters.make(for: configuration)
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            // Elapsed time rather than a date: a reference date is around 8e8, which a 32-bit float can't hold to
            // sub-second precision.
            let elapsed = Float(timeline.date.timeIntervalSince(startDate))

            // The fill only gives the shader something to draw on. It ignores the input color.
            Rectangle()
                .fill(.white)
                .colorEffect(
                    ShaderLibrary.snowfall(
                        .boundingRect,
                        .float(elapsed),
                        .floatArray(parameters)
                    )
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.black
        MetalShaderSnowView()
    }
    .ignoresSafeArea()
}
