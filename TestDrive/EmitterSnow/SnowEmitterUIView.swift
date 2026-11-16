//
//  SnowEmitterUIView.swift
//  TestDrive
//

import UIKit
import EmitterBehaviors

/// A non-interactive view that rains snow down continuously from its top edge.
///
/// Each depth band (``SnowLayerStyle``) is its own `CAEmitterLayer`, so every band gets its own width, density and
/// wind drift. `EmitterBehaviors` adds a side-to-side sway and the drag that keeps each flake at a steady fall speed.
final class SnowEmitterUIView: UIView {

    /// The snowfall parameters. Changing them rebuilds the emitters.
    var configuration: SnowfallConfiguration = .default {
        didSet {
            guard configuration != oldValue else { return }
            configuredSize = .zero
            setNeedsLayout()
        }
    }

    /// Whether snow is falling. Turn off to respect Reduce Motion.
    var isEmitting = true {
        didSet {
            for emitterLayer in emitterLayers {
                emitterLayer.birthRate = isEmitting ? 1 : 0
            }
        }
    }

    private var emitterLayers: [CAEmitterLayer] = []
    private var configuredSize: CGSize = .zero

    /// Drag coefficient shared by every flake. Gravity and wind are scaled by this to hit a target speed.
    private static let drag: CGFloat = 1

    /// Extra distance, in points, a flake travels beyond the bottom edge before it dies.
    private let bottomOvershoot: CGFloat = 20

    // MARK: - Initializer

    /// Creates a snow view.
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0, bounds.height > 0 else { return }

        // Lifetimes and widths depend on the size, so only rebuild when it (or the configuration) changes.
        guard bounds.size != configuredSize else { return }
        configuredSize = bounds.size
        rebuildEmitters()
    }

    // MARK: - Private Helpers

    /// Replaces the emitter layers with ones built for the current size and configuration.
    private func rebuildEmitters() {
        emitterLayers.forEach { $0.removeFromSuperlayer() }

        // Far to near, so nearer flakes draw on top.
        emitterLayers = SnowLayerStyle.all.map(makeEmitterLayer(for:))
        emitterLayers.forEach { layer.addSublayer($0) }
    }

    /// Creates the emitter for a depth band.
    /// - Parameter style: The depth band the emitter represents.
    /// - Returns: A line emitter above the top edge, pre-warmed so snow is already falling.
    private func makeEmitterLayer(for style: SnowLayerStyle) -> CAEmitterLayer {
        let speed = style.speed * configuration.speedMultiplier
        let travelHeight = bounds.height + bottomOvershoot

        // Padded because flakes spend a moment accelerating up to their terminal speed.
        let fallTime = travelHeight / speed * 1.15

        // Sideways drift in points per second, felt more by near flakes. Flakes born over the screen would all
        // blow off one side, so the emitter is widened on the upwind side to keep the screen evenly covered.
        let drift = configuration.windDrift * style.windFactor
        let driftTravel = abs(drift) * fallTime
        let emitterWidth = bounds.width + driftTravel
        let emitterCenterX = bounds.midX - (drift >= 0 ? driftTravel : -driftTravel) / 2

        // Flakes alive on screen at once = birth rate x the time one spends crossing it, so solve for the birth
        // rate that puts this band's share of `flakeCount` on screen. Widening the emitter dilutes it, so scale up.
        let flakesInBand = CGFloat(configuration.flakeCount) / CGFloat(SnowLayerStyle.bandCount)
        let birthRate = flakesInBand * speed / travelHeight * emitterWidth / bounds.width

        // Emitter cells read an image's pixel size as points unless told the scale, so the two must match.
        let screenScale = window?.screen.scale ?? traitCollection.displayScale
        let imageScale = screenScale > 0 ? screenScale : 3

        let cell = CAEmitterCell()
        cell.contents = SnowFlakeImage.make(sprite: style.sprite, scale: imageScale)
        cell.contentsScale = imageScale
        cell.birthRate = Float(birthRate)
        cell.lifetime = Float(fallTime)
        cell.scale = style.size / SnowFlakeImage.diameter
        cell.scaleRange = style.sizeRange / SnowFlakeImage.diameter
        cell.color = UIColor(white: 1, alpha: CGFloat(style.opacity)).cgColor

        // Particles fall via gravity rather than an initial velocity: with behaviors attached, the cell's own
        // velocity isn't reliably applied. Drag caps the speed at `acceleration / drag`, so scaling by the drag
        // gives each band exactly the target fall speed and sideways drift.
        cell.yAcceleration = speed * Self.drag
        cell.xAcceleration = drift * Self.drag

        let emitterLayer = CAEmitterLayer()
        emitterLayer.frame = bounds
        emitterLayer.emitterShape = .line
        emitterLayer.emitterPosition = CGPoint(x: emitterCenterX, y: -10)
        emitterLayer.emitterSize = CGSize(width: emitterWidth, height: 1)
        emitterLayer.emitterCells = [cell]
        emitterLayer.birthRate = isEmitting ? 1 : 0

        // Pre-warm so the screen is already snowing when the view appears, instead of waiting for the first flakes
        // to fall all the way down.
        emitterLayer.beginTime = CACurrentMediaTime() - CFTimeInterval(fallTime)

        emitterLayer.emitterBehaviors = [
            makeSwayBehavior(for: style),
            makeFlutterBehavior(for: style),
            makeDragBehavior()
        ]
        return emitterLayer
    }

    /// A slow, wide sideways sway whose strength follows the configuration's wind.
    private func makeSwayBehavior(for style: SnowLayerStyle) -> WaveBehavior {
        let sway = WaveBehavior()
        sway.force = [Float(configuration.windStrength * style.windFactor), 0, 0]
        sway.frequency = 0.3
        return sway
    }

    /// A faster, smaller sideways wobble layered over the sway so the motion isn't uniform.
    private func makeFlutterBehavior(for style: SnowLayerStyle) -> WaveBehavior {
        let flutter = WaveBehavior()
        flutter.force = [Float(configuration.windStrength * style.windFactor * 0.375), 0, 0]
        flutter.frequency = 0.9
        return flutter
    }

    /// Air resistance that turns each flake's gravity and wind into steady speeds.
    private func makeDragBehavior() -> DragBehavior {
        let drag = DragBehavior()
        drag.drag = Self.drag
        return drag
    }
}
