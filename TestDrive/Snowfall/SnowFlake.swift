//
//  SnowFlake.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// The immutable description of a single snowflake.
///
/// Flakes never mutate. Their position is a closed-form function of elapsed time, so a frame costs a handful of
/// multiplies and one `sin` per flake, with no allocation and no per-frame state.
struct SnowFlake: Equatable {
    /// Which pre-rendered sprite to draw: `0` is the soft out-of-focus layer, `2` is the crisp distant layer.
    let spriteIndex: Int

    /// Diameter in points.
    let size: CGFloat

    /// Opacity from `0...1`.
    let opacity: Double

    /// Fall speed in points per second.
    let speed: CGFloat

    /// Normalized horizontal start from `0...1`.
    let startX: CGFloat

    /// Normalized vertical start from `0...1`, so flakes are already spread over the screen at launch.
    let startY: CGFloat

    /// Amplitude of the flutter, in points.
    let swayAmplitude: CGFloat

    /// Flutter speed, in radians per second.
    let swayFrequency: Double

    /// Offset into the flutter cycle, in radians.
    let swayPhase: Double

    /// How strongly the shared wind affects this flake. Closer flakes move more, which sells the depth.
    let windFactor: CGFloat

    // MARK: - Public Helpers

    /// Generates a depth-layered set of flakes.
    /// - Parameter configuration: The snowfall parameters.
    /// - Returns: Flakes sorted far to near, so nearer flakes draw on top.
    static func makeFlakes(for configuration: SnowfallConfiguration) -> [SnowFlake] {
        var generator = SeededGenerator(seed: configuration.seed)

        let flakes = (0..<configuration.flakeCount).map { _ -> SnowFlake in
            // Depth 0 is far away, 1 is right in front of the lens. Squaring biases toward more distant flakes.
            let depth = CGFloat(Double.random(in: 0...1, using: &generator))
            let biasedDepth = depth * depth

            let spriteIndex: Int
            switch biasedDepth {
            case ..<0.45: spriteIndex = 2
            case ..<0.85: spriteIndex = 1
            default: spriteIndex = 0
            }

            let size = 2 + biasedDepth * 12
            let jitter = CGFloat(Double.random(in: 0.85...1.15, using: &generator))

            return SnowFlake(
                spriteIndex: spriteIndex,
                size: size,
                opacity: 0.35 + Double(biasedDepth) * 0.5 + Double.random(in: 0...0.15, using: &generator),
                speed: (22 + biasedDepth * 90) * jitter * configuration.speedMultiplier,
                startX: CGFloat(Double.random(in: 0...1, using: &generator)),
                startY: CGFloat(Double.random(in: 0...1, using: &generator)),
                swayAmplitude: 4 + biasedDepth * 22 + CGFloat(Double.random(in: 0...6, using: &generator)),
                swayFrequency: Double.random(in: 0.5...1.6, using: &generator),
                swayPhase: Double.random(in: 0...(2 * .pi), using: &generator),
                windFactor: 0.3 + biasedDepth * 0.7
            )
        }

        return flakes.sorted { $0.size < $1.size }
    }

    /// The center of the flake after the given amount of time.
    /// - Parameters:
    ///   - time: Seconds since the snowfall started.
    ///   - bounds: The size of the area the snow falls through.
    ///   - windStrength: Maximum horizontal travel of the shared wind, in points.
    /// - Returns: The flake's center in the bounds' coordinate space.
    func position(at time: TimeInterval, in bounds: CGSize, windStrength: CGFloat) -> CGPoint {
        // Extra room off-screen so flakes enter and leave without popping.
        let margin = size * 2 + swayAmplitude + windStrength
        let loopHeight = bounds.height + margin * 2
        let loopWidth = bounds.width + margin * 2

        let fallen = startY * loopHeight + speed * CGFloat(time)
        let y = fallen.truncatingRemainder(dividingBy: loopHeight) - margin

        // Two slow, unrelated sines make an irregular gust instead of a metronome.
        let gust = sin(time * 0.21) + 0.4 * sin(time * 0.53 + 1.3)
        let wind = CGFloat(gust) * windStrength * windFactor

        // A second, faster harmonic adds the little flutter real flakes have.
        let flutter = sin(time * swayFrequency + swayPhase)
            + 0.3 * sin(time * swayFrequency * 2.3 + swayPhase * 1.7)
        let sway = CGFloat(flutter) * swayAmplitude

        let rawX = startX * loopWidth + wind + sway
        let x = rawX.positiveRemainder(dividingBy: loopWidth) - margin

        return CGPoint(x: x, y: y)
    }
}

private extension CGFloat {
    /// A remainder that is never negative, so flakes pushed off the left edge wrap to the right.
    func positiveRemainder(dividingBy divisor: CGFloat) -> CGFloat {
        let remainder = truncatingRemainder(dividingBy: divisor)
        return remainder < 0 ? remainder + divisor : remainder
    }
}
