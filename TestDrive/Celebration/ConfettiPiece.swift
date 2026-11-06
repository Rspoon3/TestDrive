//
//  ConfettiPiece.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// The immutable description of one piece of Canvas confetti.
///
/// A piece's pose is a closed-form function of time (see ``DragMotion``), so nothing is mutated per frame. Real confetti
/// is paper: it leaves the cannon fast, air slows it within a second or two, and then it drifts down at a low terminal
/// speed while swaying, spinning, and flipping over. Each of those is a separate term below.
struct ConfettiPiece: Equatable {
    /// Where a piece is and how it is turned at one moment.
    struct Pose: Equatable {
        /// The center of the piece.
        let center: CGPoint

        /// Rotation in radians.
        let rotation: CGFloat

        /// Vertical squash from `-1...1`, which fakes the piece tumbling in 3D. Near zero the piece is edge-on, and a
        /// negative value means its back is facing the viewer.
        let flip: CGFloat
    }

    /// Index into ``ConfettiPalette``.
    let colorIndex: Int

    /// Whether the piece is a dot instead of a rectangle.
    let isCircle: Bool

    /// Size in points.
    let size: CGSize

    /// Seconds after the show starts that the piece is launched.
    let delay: TimeInterval

    /// Normalized launch point, where `(0, 0)` is the top left of the screen.
    let origin: CGPoint

    /// Launch velocity in points per second.
    let velocity: CGVector

    /// Downward acceleration in points per second squared.
    let gravity: CGFloat

    /// Air resistance. With gravity this sets the terminal fall speed.
    let drag: CGFloat

    /// How far the piece sways side to side as it falls, in points.
    let swayAmplitude: CGFloat

    /// Sway speed in radians per second.
    let swayFrequency: Double

    /// Offset into the sway cycle, in radians.
    let swayPhase: Double

    /// Spin in radians per second. Negative spins the other way.
    let spinSpeed: Double

    /// Starting rotation in radians.
    let spinPhase: Double

    /// Tumble speed in radians per second.
    let flipSpeed: Double

    /// Offset into the tumble cycle, in radians.
    let flipPhase: Double

    // MARK: - Public Helpers

    /// Generates the pieces for a confetti show.
    /// - Parameters:
    ///   - style: How the confetti arrives.
    ///   - seed: The same seed always gives the same show.
    /// - Returns: The pieces, in no particular order.
    static func makePieces(for style: ConfettiStyle, seed: UInt64 = 2026) -> [ConfettiPiece] {
        var generator = SeededGenerator(seed: seed)

        switch style {
        case .cannonBlast:
            return (0..<280).map { index in
                // Two cannons in the bottom corners, each firing up and in toward the middle.
                let fromLeft = index.isMultiple(of: 2)
                let lean = Double.random(in: 18...58, using: &generator) * .pi / 180
                let speed = Double.random(in: 700...1_500, using: &generator)
                let direction = CGVector(
                    dx: CGFloat(sin(lean)) * (fromLeft ? 1 : -1),
                    dy: -CGFloat(cos(lean))
                )

                return randomPiece(
                    origin: CGPoint(x: fromLeft ? -0.02 : 1.02, y: 1.02),
                    velocity: CGVector(dx: direction.dx * speed, dy: direction.dy * speed),
                    delay: Double.random(in: 0...0.12, using: &generator),
                    swayRange: 8...26,
                    using: &generator
                )
            }

        case .rain:
            return (0..<200).map { _ in
                randomPiece(
                    origin: CGPoint(x: Double.random(in: 0...1, using: &generator), y: -0.04),
                    velocity: CGVector(
                        dx: CGFloat.random(in: -20...20, using: &generator),
                        dy: CGFloat.random(in: 120...220, using: &generator)
                    ),
                    delay: Double.random(in: 0...3.5, using: &generator),
                    swayRange: 14...40,
                    using: &generator
                )
            }
        }
    }

    /// The piece's pose after the given amount of time.
    /// - Parameters:
    ///   - time: Seconds since the show started.
    ///   - bounds: The size of the area the confetti fills.
    /// - Returns: The pose, or `nil` if the piece hasn't been launched yet.
    func pose(at time: TimeInterval, in bounds: CGSize) -> Pose? {
        let local = time - delay
        guard local >= 0 else { return nil }

        let seconds = CGFloat(local)
        let moved = DragMotion.displacement(velocity: velocity, gravity: gravity, drag: drag, time: seconds)

        // The sway fades in as the launch speed dies away, so a piece doesn't wobble while it is being fired.
        let swayStrength = min(1, seconds * 1.5)
        let sway = CGFloat(sin(local * swayFrequency + swayPhase)) * swayAmplitude * swayStrength

        return Pose(
            center: CGPoint(
                x: origin.x * bounds.width + moved.dx + sway,
                y: origin.y * bounds.height + moved.dy
            ),
            rotation: CGFloat(spinPhase + local * spinSpeed),
            flip: CGFloat(cos(local * flipSpeed + flipPhase))
        )
    }

    // MARK: - Private Helpers

    private static func randomPiece(
        origin: CGPoint,
        velocity: CGVector,
        delay: TimeInterval,
        swayRange: ClosedRange<CGFloat>,
        using generator: inout SeededGenerator
    ) -> ConfettiPiece {
        let isCircle = Double.random(in: 0...1, using: &generator) < 0.25
        let size: CGSize = if isCircle {
            CGSize(width: CGFloat.random(in: 5...7, using: &generator), height: CGFloat.random(in: 5...7, using: &generator))
        } else {
            CGSize(width: CGFloat.random(in: 8...12, using: &generator), height: CGFloat.random(in: 5...7, using: &generator))
        }

        return ConfettiPiece(
            colorIndex: Int.random(in: 0..<ConfettiPalette.colors.count, using: &generator),
            isCircle: isCircle,
            size: size,
            delay: delay,
            origin: origin,
            velocity: velocity,
            gravity: CGFloat.random(in: 180...260, using: &generator),
            drag: CGFloat.random(in: 2...2.8, using: &generator),
            swayAmplitude: CGFloat.random(in: swayRange, using: &generator),
            swayFrequency: Double.random(in: 2...5, using: &generator),
            swayPhase: Double.random(in: 0...(2 * .pi), using: &generator),
            spinSpeed: Double.random(in: 4...14, using: &generator) * (Bool.random(using: &generator) ? 1 : -1),
            spinPhase: Double.random(in: 0...(2 * .pi), using: &generator),
            flipSpeed: Double.random(in: 5...12, using: &generator),
            flipPhase: Double.random(in: 0...(2 * .pi), using: &generator)
        )
    }
}
