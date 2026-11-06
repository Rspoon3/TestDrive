//
//  EmitterConfettiHostView.swift
//  TestDrive
//

import UIKit

/// A `UIView` that runs a Core Animation confetti show once it has a size, then cleans itself up.
@MainActor
final class EmitterConfettiHostView: UIView {
    private let style: ConfettiStyle
    private var hasStarted = false

    // MARK: - Initializer

    /// Creates the view.
    /// - Parameter style: How the confetti arrives.
    init(style: ConfettiStyle) {
        self.style = style
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        startIfNeeded()
    }

    // MARK: - Private Helpers

    /// Emitters need the real bounds to position themselves, so the show starts on the first layout with a size.
    private func startIfNeeded() {
        guard !hasStarted, bounds.width > 0, bounds.height > 0 else { return }
        hasStarted = true

        let builder = EmitterConfettiBuilder(style: style, displayScale: traitCollection.displayScale)
        for emitter in builder.makeLayers(in: bounds) {
            layer.addSublayer(emitter)
        }

        Task { [weak self] in
            await self?.runLifecycle()
        }
    }

    /// Stops new pieces, lets the rest fall, then fades out and removes the layers.
    private func runLifecycle() async {
        // Rain keeps emitting for a few seconds. The cannon blast is a one-second burst that stops itself.
        let emitDuration: Double = style == .rain ? 4 : 0.1
        let lingerDuration: Double = style == .rain ? 3 : 4.9

        try? await Task.sleep(for: .seconds(emitDuration))
        emitterLayers.forEach { $0.birthRate = 0 }

        try? await Task.sleep(for: .seconds(lingerDuration))
        UIView.animate(withDuration: 1) {
            self.alpha = 0
        } completion: { _ in
            self.emitterLayers.forEach { $0.removeFromSuperlayer() }
        }
    }

    private var emitterLayers: [CAEmitterLayer] {
        (layer.sublayers ?? []).compactMap { $0 as? CAEmitterLayer }
    }
}
