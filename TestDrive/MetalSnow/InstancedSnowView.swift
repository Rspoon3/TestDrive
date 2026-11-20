//
//  InstancedSnowView.swift
//  TestDrive
//

import MetalKit
import SwiftUI

/// A full-bleed snowfall drawn with a single instanced Metal draw call in an `MTKView`.
///
/// This is the Canvas snow ported to the GPU: it uses the very same flakes (`SnowFlake.makeFlakes(for:)`) and the same
/// position formula, but the formula runs in a vertex shader instead of on the CPU. See ``InstancedSnowRenderer``. As
/// with the other GPU snow views, far flakes are soft and near flakes sharper. There is no snow pile and no haze.
struct InstancedSnowView: UIViewRepresentable {
    private let configuration: SnowfallConfiguration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates the snow.
    /// - Parameter configuration: How much snow falls, how fast, and how windy it is.
    init(configuration: SnowfallConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.framebufferOnly = true
        view.preferredFramesPerSecond = 120
        view.isUserInteractionEnabled = false

        if let renderer = InstancedSnowRenderer(view: view, configuration: configuration) {
            context.coordinator.renderer = renderer
            view.delegate = renderer
        }

        updateMotion(of: view)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.update(configuration: configuration)
        updateMotion(of: uiView)
    }

    // MARK: - Private Helpers

    /// Stops drawing and hides the view when the user prefers reduced motion.
    private func updateMotion(of view: MTKView) {
        view.isPaused = reduceMotion
        view.isHidden = reduceMotion
    }

    // MARK: - Coordinator

    /// Keeps the renderer alive, because `MTKView` only holds its delegate weakly.
    final class Coordinator {
        var renderer: InstancedSnowRenderer?
    }
}

#Preview {
    ZStack {
        Color.black
        InstancedSnowView()
    }
    .ignoresSafeArea()
}
