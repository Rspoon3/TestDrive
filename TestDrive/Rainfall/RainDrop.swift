//
//  RainDrop.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// The immutable description of a single raindrop, drawn as a streak.
///
/// Like ``SnowFlake``, a drop's position is a closed-form function of elapsed time, so nothing is mutated per frame.
struct RainDrop: Equatable {
    /// Number of depth layers. Layer `0` is far away, the last layer is closest.
    static let layerCount = 3

    /// Stroke width per layer, in points.
    static let lineWidths: [CGFloat] = [0.8, 1.2, 1.8]

    /// Stroke opacity per layer. Far drops are fainter.
    static let opacities: [Double] = [0.22, 0.32, 0.45]

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

            let speed = CGFloat(Double.random(in: speedRange, using: &generator)) * configuration.speedMultiplier
            let jitter = CGFloat(Double.random(in: 0.9...1.1, using: &generator))

            return RainDrop(
                layer: layer,
                length: speed * 0.045 * jitter,
                speed: speed,
                startX: CGFloat(Double.random(in: 0...1, using: &generator)),
                startY: CGFloat(Double.random(in: 0...1, using: &generator))
            )
        }
    }

    /// The leading (lowest) end of the streak after the given amount of time.
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
}
