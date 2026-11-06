//
//  LightningStrike.swift
//  TestDrive
//

import CoreGraphics
import Foundation
import SwiftUI

/// A single lightning strike: a jagged bolt plus the flickering flash it throws across the sky.
///
/// Strikes are deterministic. Time is split into fixed slots, and each slot's strike (or lack of one) is derived from
/// the seed and the slot number. That means nothing is scheduled or stored, and any moment can be recomputed on its own.
struct LightningStrike: Equatable {
    /// One burst of light. Real lightning flickers: a sharp first flash, a weaker restrike, then a longer return stroke.
    struct Pulse: Equatable {
        /// Seconds after the strike starts that the pulse begins.
        let offset: TimeInterval

        /// How long the pulse takes to fade out.
        let duration: TimeInterval

        /// Brightness at the start of the pulse, from `0...1`.
        let peak: Double
    }

    /// Length of each time slot, in seconds. A strike always finishes inside its own slot.
    static let slotLength: TimeInterval = 4.5

    /// Chance that a slot contains a strike. Together with ``slotLength`` this gives a strike roughly every 5 seconds.
    private static let strikeProbability = 0.9

    /// When the strike begins, in seconds since the rain started.
    let startTime: TimeInterval

    /// Normalized horizontal position of the bolt's top, from `0...1`.
    let boltX: CGFloat

    /// Seed for the bolt's jagged shape.
    let boltSeed: UInt64

    /// The flashes that make up the strike, in order.
    let pulses: [Pulse]

    // MARK: - Public Helpers

    /// The strike scheduled in the time slot that contains `time`, if there is one.
    /// - Parameters:
    ///   - time: Seconds since the rain started.
    ///   - seed: Seed that makes the schedule reproducible.
    /// - Returns: The strike, or `nil` if the slot is quiet. The strike may not have started yet.
    static func strike(at time: TimeInterval, seed: UInt64) -> LightningStrike? {
        guard time >= 0 else { return nil }
        return strike(inSlot: Int(time / slotLength), seed: seed)
    }

    /// The flash brightness at a moment in time.
    /// - Parameter time: Seconds since the rain started.
    /// - Returns: Brightness from `0...1`. Zero before the strike, between pulses, and after it ends.
    func intensity(at time: TimeInterval) -> Double {
        let elapsed = time - startTime
        guard elapsed >= 0 else { return 0 }

        return pulses.reduce(0) { brightest, pulse in
            let local = elapsed - pulse.offset
            guard local >= 0, local < pulse.duration else { return brightest }

            // Instant rise and a fast, slightly curved fade, like a real flash.
            return max(brightest, pulse.peak * pow(1 - local / pulse.duration, 1.6))
        }
    }

    /// The bolt's shape, with its side branches kept separate so they can be drawn thinner.
    /// - Parameter size: The size of the area the bolt is drawn in.
    /// - Returns: The main channel and the branches.
    func boltPaths(in size: CGSize) -> (main: Path, branches: Path) {
        var generator = SeededGenerator(seed: boltSeed)
        var main = Path()
        var branches = Path()

        var point = CGPoint(x: boltX * size.width, y: -10)
        let endY = size.height * CGFloat(Double.random(in: 0.6...0.9, using: &generator))
        main.move(to: point)

        while point.y < endY {
            point.y += CGFloat(Double.random(in: 25...55, using: &generator))
            point.x += CGFloat(Double.random(in: -28...28, using: &generator))
            main.addLine(to: point)

            if Double.random(in: 0...1, using: &generator) < 0.3 {
                var branch = point
                let direction: CGFloat = Bool.random(using: &generator) ? 1 : -1
                let segments = Int.random(in: 3...6, using: &generator)

                branches.move(to: branch)
                for _ in 0..<segments {
                    branch.y += CGFloat(Double.random(in: 15...35, using: &generator))
                    branch.x += direction * CGFloat(Double.random(in: 8...30, using: &generator))
                    branches.addLine(to: branch)
                }
            }
        }

        return (main, branches)
    }

    // MARK: - Private Helpers

    private static func strike(inSlot slot: Int, seed: UInt64) -> LightningStrike? {
        var generator = SeededGenerator(seed: seed ^ (UInt64(slot) &* 0x9E37_79B9_7F4A_7C15))

        guard Double.random(in: 0...1, using: &generator) < strikeProbability else { return nil }

        // Leave a second at the start of the slot and 2.5s at the end, so a strike finishes inside its slot.
        let startTime = Double(slot) * slotLength + Double.random(in: 1...(slotLength - 2.5), using: &generator)

        var pulses = [
            Pulse(offset: 0, duration: 0.09, peak: 1),
            Pulse(
                offset: Double.random(in: 0.1...0.16, using: &generator),
                duration: 0.08,
                peak: Double.random(in: 0.5...0.8, using: &generator)
            ),
            Pulse(
                offset: Double.random(in: 0.25...0.35, using: &generator),
                duration: Double.random(in: 0.3...0.5, using: &generator),
                peak: Double.random(in: 0.7...1, using: &generator)
            )
        ]

        // Sometimes a faint late restrike.
        if Double.random(in: 0...1, using: &generator) < 0.4 {
            pulses.append(Pulse(offset: Double.random(in: 0.7...0.9, using: &generator), duration: 0.2, peak: 0.4))
        }

        return LightningStrike(
            startTime: startTime,
            boltX: CGFloat(Double.random(in: 0.15...0.85, using: &generator)),
            boltSeed: generator.next(),
            pulses: pulses
        )
    }
}
