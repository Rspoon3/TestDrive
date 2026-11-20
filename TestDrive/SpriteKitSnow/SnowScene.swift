//
//  SnowScene.swift
//  TestDrive
//

import SpriteKit

/// A SpriteKit scene that rains snow from `SKEmitterNode`s, one per depth band (``SnowLayerStyle``).
///
/// SpriteKit renders on the GPU through Metal. Particles fall at a constant speed along an angle that blends gravity
/// and wind drift, and a repeating `particleAction` adds the sideways sway. The scene is transparent so it can sit over
/// other content.
final class SnowScene: SKScene {

    /// The snowfall parameters. Changing them rebuilds the emitters.
    var configuration: SnowfallConfiguration {
        didSet {
            guard configuration != oldValue else { return }
            rebuildEmitters()
        }
    }

    /// Extra distance, in points, a flake travels beyond the bottom edge before it dies.
    private let bottomOvershoot: CGFloat = 20

    // MARK: - Initializer

    /// Creates a snow scene.
    /// - Parameter configuration: How much snow falls, how fast, and how windy it is.
    init(configuration: SnowfallConfiguration = .default) {
        self.configuration = configuration
        super.init(size: .zero)

        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - SKScene

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        rebuildEmitters()
    }

    // MARK: - Private Helpers

    /// Replaces the emitters with ones built for the current size and configuration.
    private func rebuildEmitters() {
        removeAllChildren()

        guard size.width > 0, size.height > 0 else { return }

        // Far to near, so nearer flakes draw on top.
        for (index, style) in SnowLayerStyle.all.enumerated() {
            let emitter = makeEmitter(for: style)
            emitter.zPosition = CGFloat(index)
            addChild(emitter)
        }
    }

    /// Creates the emitter for a depth band.
    /// - Parameter style: The depth band the emitter represents.
    /// - Returns: An emitter above the top edge, advanced so snow is already falling.
    private func makeEmitter(for style: SnowLayerStyle) -> SKEmitterNode {
        let speed = style.speed * configuration.speedMultiplier
        let travelHeight = size.height + bottomOvershoot
        let fallTime = travelHeight / speed

        // Sideways drift in points per second, felt more by near flakes. As with the other emitters, the emitter is
        // widened on the upwind side so the screen stays evenly covered.
        let drift = configuration.windDrift * style.windFactor
        let driftTravel = abs(drift) * fallTime
        let emitterWidth = size.width + driftTravel
        let emitterCenterX = size.width / 2 - (drift >= 0 ? driftTravel : -driftTravel) / 2

        // Flakes on screen at once = birth rate x the time one spends crossing it, so solve for the birth rate that
        // puts this band's share of `flakeCount` on screen.
        let flakesInBand = CGFloat(configuration.flakeCount) / CGFloat(SnowLayerStyle.bandCount)
        let birthRate = flakesInBand * speed / travelHeight * emitterWidth / size.width

        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(cgImage: flakeImage(for: style))
        emitter.particleSize = CGSize(width: style.size, height: style.size)
        emitter.particleScale = 1
        emitter.particleScaleRange = style.sizeRange * 2 / style.size
        emitter.particleAlpha = CGFloat(style.opacity)
        emitter.particleColorBlendFactor = 0
        emitter.particleBlendMode = .alpha

        emitter.particleBirthRate = birthRate
        emitter.particleLifetime = fallTime
        emitter.particlePositionRange = CGVector(dx: emitterWidth, dy: 0)
        emitter.position = CGPoint(x: emitterCenterX, y: size.height + 10)

        // SpriteKit's y axis points up, so straight down is -90 degrees, and positive drift tilts it toward +x.
        emitter.particleSpeed = hypot(speed, drift)
        emitter.emissionAngle = atan2(-speed, drift)

        emitter.particleAction = swayAction(for: style)

        // Pre-warm so the screen is already snowing when the scene appears.
        emitter.advanceSimulationTime(TimeInterval(fallTime))
        return emitter
    }

    /// A repeating sideways sway. Near flakes sway further, as in the Canvas snow.
    /// - Parameter style: The depth band the sway is for.
    /// - Returns: An action that moves a particle back and forth without net travel.
    private func swayAction(for style: SnowLayerStyle) -> SKAction {
        let depth = (style.windFactor - 0.3) / 0.7
        let amplitude = 4 + depth * 22
        let period: TimeInterval = 4

        let out = SKAction.moveBy(x: amplitude, y: 0, duration: period / 4)
        let back = SKAction.moveBy(x: -amplitude * 2, y: 0, duration: period / 2)
        let home = SKAction.moveBy(x: amplitude, y: 0, duration: period / 4)

        for action in [out, back, home] {
            action.timingMode = .easeInEaseOut
        }

        return .repeatForever(.sequence([out, back, home]))
    }

    /// Renders the sprite for a depth band.
    /// - Parameter style: The depth band the flake image is for.
    /// - Returns: The sprite image. Falls back to a 1 x 1 clear image if rendering fails.
    private func flakeImage(for style: SnowLayerStyle) -> CGImage {
        let scale = view?.window?.screen.scale ?? 3

        return SnowFlakeImage.make(sprite: style.sprite, scale: scale)
            ?? UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in }.cgImage!
    }
}
