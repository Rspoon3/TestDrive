//
//  RainDrop.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// The immutable description of a single raindrop, drawn as a streak that splashes when it lands.
///
/// Like ``SnowFlake``, a drop's position is a closed-form function of elapsed time, and so is its splash: whether it
/// has landed recently, and how long ago, falls out of the same arithmetic. Nothing is mutated per frame.
struct RainDrop: Equatable {
    /// A splash in progress where a drop has just landed.
    struct Splash: Equatable {
        /// Horizontal position of the impact.
        let x: CGFloat

        /// Vertical position of the impact, on the ground line.
        let y: CGFloat

        /// Seconds since the drop landed.
        let age: TimeInterval

        /// A repeatable value from `0..<1` that varies the splash from landing to landing.
        let variation: Double
    }

    /// Number of depth layers. Layer `0` is far away, the last layer is closest.
    static let layerCount = 3

    /// Stroke width per layer, in points.
    static let lineWidths: [CGFloat] = [0.8, 1.2, 1.8]

    /// Stroke opacity per layer. Far drops are fainter.
    static let opacities: [Double] = [0.22, 0.32, 0.45]

    /// Size of a splash per layer. Far splashes are smaller.
    static let splashScales: [CGFloat] = [0.6, 0.85, 1.1]

    /// How long a splash lasts, in seconds.
    static let splashLifetime: TimeInterval = 0.32

    /// The depth layer this drop belongs to.
    let layer: Int

    /// Streak length in points. Faster drops get longer streaks, like motion blur.
    let length: CGFloat

    /// Fall speed in points per second.
    let speed: CGFloat

    /// Normalized horizontal start from `0...1`.
    let startX: CGFloat

    /// Normalized vertical start from `0...1`, so drops are already spread over the screen at launch.
    let startY: CGFloat

    /// How far above the bottom of the screen this drop lands. Far drops land higher up, which gives the ground depth
    /// instead of a single flat line.
    let landingOffset: CGFloat

    /// A stable value from `0...1` that decides whether this drop splashes, so lighter rain splashes fewer drops.
    let splashRoll: Double

    // MARK: - Public Helpers

    /// Generates a depth-layered set of drops.
    /// - Parameter configuration: The rainfall parameters.
    /// - Returns: The generated drops.
    static func makeDrops(for configuration: RainfallConfiguration) -> [RainDrop] {
        var generator = SeededGenerator(seed: configuration.seed)

        return (0..<configuration.dropCount).map { _ in
            // Roughly half far, a third mid, a sixth near.
            let roll = Double.random(in: 0...1, using: &generator)
            let layer = roll < 0.5 ? 0 : (roll < 0.83 ? 1 : 2)

            let speedRange: ClosedRange<Double> = switch layer {
            case 0: 520...700
            case 1: 800...1050
            default: 1150...1500
            }

            let offsetRange: ClosedRange<Double> = switch layer {
            case 0: 45...95
            case 1: 15...50
            default: 0...14
            }

            let speed = CGFloat(Double.random(in: speedRange, using: &generator)) * configuration.speedMultiplier
            let jitter = CGFloat(Double.random(in: 0.9...1.1, using: &generator))

            return RainDrop(
                layer: layer,
                length: speed * 0.045 * jitter,
                speed: speed,
                startX: CGFloat(Double.random(in: 0...1, using: &generator)),
                startY: CGFloat(Double.random(in: 0...1, using: &generator)),
                landingOffset: CGFloat(Double.random(in: offsetRange, using: &generator)),
                splashRoll: Double.random(in: 0...1, using: &generator)
            )
        }
    }

    /// The leading (lowest) end of the streak after the given amount of time, ignoring the ground.
    /// - Parameters:
    ///   - time: Seconds since the rain started.
    ///   - bounds: The size of the area the rain falls through.
    ///   - slantRadians: How far the wind leans the rain from vertical.
    /// - Returns: The head of the streak in the bounds' coordinate space.
    func position(at time: TimeInterval, in bounds: CGSize, slantRadians: CGFloat) -> CGPoint {
        // Extra room off-screen so streaks enter and leave without popping.
        let loopHeight = bounds.height + length * 2
        let loopWidth = bounds.width + length * 2

        let fallen = startY * loopHeight + speed * CGFloat(time)
        let y = fallen.truncatingRemainder(dividingBy: loopHeight) - length

        // Rain travels along the slant, so sideways movement is proportional to distance fallen.
        let rawX = startX * loopWidth + tan(slantRadians) * fallen
        let x = rawX.positiveRemainder(dividingBy: loopWidth) - length

        return CGPoint(x: x, y: y)
    }

    /// The y coordinate of the ground this drop lands on.
    /// - Parameter bounds: The size of the area the rain falls through.
    func groundY(in bounds: CGSize) -> CGFloat {
        bounds.height - landingOffset
    }

    /// The splash this drop is making right now, if it landed within the last ``splashLifetime`` seconds.
    /// - Parameters:
    ///   - time: Seconds since the rain started.
    ///   - bounds: The size of the area the rain falls through.
    ///   - slantRadians: How far the wind leans the rain from vertical.
    /// - Returns: The splash, or `nil` if the drop isn't splashing.
    func splash(at time: TimeInterval, in bounds: CGSize, slantRadians: CGFloat) -> Splash? {
        let loopHeight = bounds.height + length * 2
        let ground = groundY(in: bounds)

        // The head is at y = phase - length, so it meets the ground when the phase reaches ground + length.
        let landingPhase = ground + length
        let fallen = startY * loopHeight + speed * CGFloat(time)
        guard fallen >= landingPhase else { return nil }

        let sinceLanding = fallen - landingPhase
        let age = TimeInterval(sinceLanding.truncatingRemainder(dividingBy: loopHeight) / speed)
        guard age < Self.splashLifetime else { return nil }

        // Which landing this is, so the same drop splashes a little differently each time it falls.
        let landingCount = Int(sinceLanding / loopHeight)
        let variation = (splashRoll * 7.31 + Double(landingCount) * 0.618_033_988_75)
            .truncatingRemainder(dividingBy: 1)

        // Where the drop was horizontally at the moment it landed.
        let impact = position(at: time - age, in: bounds, slantRadians: slantRadians)

        return Splash(x: impact.x, y: ground, age: age, variation: variation)
    }
}
