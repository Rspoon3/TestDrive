//
//  EmitterConfettiView.swift
//  TestDrive
//

import SwiftUI

/// Confetti drawn by Core Animation particle emitters (`CAEmitterLayer`), the approach the Fetch app uses.
///
/// This is the first of the two confetti implementations. The emitter does all the particle work on the render server,
/// so it is cheap on the CPU, but emitted particles can't be changed after they're born, which is why the motion is
/// shaped by animating the emitter's properties over time instead. See ``EmitterConfettiBuilder`` for what is
/// reproduced from Fetch and what is left out. The second implementation is ``CanvasConfettiView``.
struct EmitterConfettiView: UIViewRepresentable {
    private let style: ConfettiStyle

    // MARK: - Initializer

    /// Creates a confetti show.
    /// - Parameter style: How the confetti arrives.
    init(style: ConfettiStyle) {
        self.style = style
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> EmitterConfettiHostView {
        let view = EmitterConfettiHostView(style: style)

        // Flying paper is exactly the kind of motion Reduce Motion is meant to remove.
        view.isHidden = context.environment.accessibilityReduceMotion

        return view
    }

    func updateUIView(_ uiView: EmitterConfettiHostView, context: Context) {}
}
