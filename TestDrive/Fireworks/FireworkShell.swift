//
//  FireworkShell.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// One firework shell: a rocket that climbs to its apex and then bursts into sparks.
///
/// A shell is a pure function of time. Which shells exist is derived from time slots and a seed, and each spark's
/// angle and speed come from a cheap hash of its index, so nothing is stored or stepped per frame.
struct FireworkShell: Equatable {
    /// The rocket while it climbs.
    struct Rocket: Equatable {
        /// The glowing front of the rocket.
        let head: CGPoint

        /// A point a little way back along its path, giving it a tail.
        let tail: CGPoint
    }

    /// One spark of the burst, drawn as a short streak.
    struct Spark: Equatable {
        /// Where the streak starts (the spark's recent past).
        let from: CGPoint

        /// Where the spark is now.
        let to: CGPoint

        /// Brightness from `0...1`.
        let alpha: Double

        /// Which of the shell's two colors the spark uses: `0` for the main color, `1` for the accent.
        let group: Int
    }

    /// How long the rocket takes to reach its apex, in seconds.
    static let riseDuration: TimeInterval = 1

    /// Seconds after the show starts that the rocket is launched.
    let launchTime: TimeInterval

    /// The burst pattern.
    let kind: FireworkKind

    /// Normalized horizontal launch position, along the bottom of the screen.
    let launchX: CGFloat

    /// Normalized position of the burst.
    let apex: CGPoint

    /// The main color's hue, from `0...1`.
    let hue: Double

    /// The accent color's hue, from `0...1`.
    let accentHue: Double

    /// A value that varies the sparks from shell to shell.
    let seed: Double

    // MARK: - Public Helpers

    /// The shells that are climbing or bursting at a moment in time.
    /// - Parameters:
    ///   - time: Seconds since the show started.
    ///   - configuration: How big the show is.
    /// - Returns: The shells in the air.
    static func shells(at time: TimeInterval, configuration: FireworksConfiguration) -> [FireworkShell] {
        guard time >= 0 else { return [] }

        // Look back far enough that a shell launched in an earlier slot is still found while its sparks are alive.
        let longestLife = riseDuration + FireworkKind.longestSparkLifetime
        let lookback = Int((longestLife / configuration.slotLength).rounded(.up)) + 1
        let currentSlot = Int(time / configuration.slotLength)

        var shells: [FireworkShell] = []
        for slot in max(0, currentSlot - lookback)...currentSlot {
            for index in 0..<configuration.shellsPerSlot {
                guard let shell = shell(inSlot: slot, index: index, configuration: configuration),
                      shell.isActive(at: time)
                else { continue }

                shells.append(shell)
            }
        }

        return shells
    }

    /// The point where the shell bursts.
    /// - Parameter bounds: The size of the area the show fills.
    func apexPoint(in bounds: CGSize) -> CGPoint {
        CGPoint(x: apex.x * bounds.width, y: apex.y * bounds.height)
    }

    /// The rocket's position while it climbs.
    /// - Parameters:
    ///   - time: Seconds since the show started.
    ///   - bounds: The size of the area the show fills.
    /// - Returns: The rocket, or `nil` if it hasn't launched or has already burst.
    func rocket(at time: TimeInterval, in bounds: CGSize) -> Rocket? {
        let progress = (time - launchTime) / Self.riseDuration
        guard progress >= 0, progress < 1 else { return nil }

        return Rocket(
            head: climbingPoint(progress: progress, in: bounds),
            tail: climbingPoint(progress: max(0, progress - 0.1), in: bounds)
        )
    }

    /// How long ago the shell burst.
    /// - Parameter time: Seconds since the show started.
    /// - Returns: The age in seconds, or `nil` if the shell hasn't burst or its sparks have gone.
    func burstAge(at time: TimeInterval) -> TimeInterval? {
        let age = time - launchTime - Self.riseDuration
        guard age >= 0, age < kind.sparkLifetime else { return nil }
        return age
    }

    /// A spark of the burst.
    /// - Parameters:
    ///   - index: Which spark, from `0..<kind.sparkCount`.
    ///   - age: Seconds since the burst.
    ///   - bounds: The size of the area the show fills.
    /// - Returns: The spark, or `nil` if it has burned out.
    func spark(index: Int, age: TimeInterval, in bounds: CGSize) -> Spark? {
        guard age >= 0, age < kind.sparkLifetime else { return nil }

        let progress = age / kind.sparkLifetime

        // Sparks fade out and, near the end, flicker like burning embers.
        var flicker: Double = 1
        if progress > 0.6 {
            let phase: Double = age * 40 + hash(index, salt: 3) * 10
            flicker = 0.65 + 0.35 * sin(phase)
        }
        let alpha: Double = pow(1 - progress, 1.3) * flicker

        let angle: Double
        let speed: Double
        let group: Int

        switch kind {
        case .peony:
            angle = 2 * .pi * hash(index, salt: 1)
            // The square root pushes more sparks toward the rim, which is what makes a burst look round and full.
            speed = kind.sparkSpeed * (0.3 + 0.7 * hash(index, salt: 2).squareRoot())
            group = hash(index, salt: 4) < 0.25 ? 1 : 0
        case .ring:
            let evenlySpaced: Double = 2 * Double.pi * Double(index) / Double(kind.sparkCount)
            let wobble: Double = (hash(index, salt: 1) - 0.5) * 0.05
            angle = evenlySpaced + wobble
            speed = kind.sparkSpeed * (0.97 + 0.06 * hash(index, salt: 2))
            group = index % 2
        case .willow:
            angle = 2 * .pi * hash(index, salt: 1)
            speed = kind.sparkSpeed * (0.45 + 0.55 * hash(index, salt: 2).squareRoot())
            group = 0
        }

        let velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
        let center = apexPoint(in: bounds)

        let now = DragMotion.displacement(velocity: velocity, gravity: kind.gravity, drag: kind.drag, time: CGFloat(age))
        let before = DragMotion.displacement(
            velocity: velocity,
            gravity: kind.gravity,
            drag: kind.drag,
            time: CGFloat(max(0, age - kind.trailLength))
        )

        return Spark(
            from: CGPoint(x: center.x + before.dx, y: center.y + before.dy),
            to: CGPoint(x: center.x + now.dx, y: center.y + now.dy),
            alpha: alpha,
            group: group
        )
    }

    // MARK: - Private Helpers

    private func isActive(at time: TimeInterval) -> Bool {
        time >= launchTime && time < launchTime + Self.riseDuration + kind.sparkLifetime
    }

    /// The rocket's position part-way up. It eases out, so it is fast off the ground and slows near the top.
    private func climbingPoint(progress: Double, in bounds: CGSize) -> CGPoint {
        let eased = CGFloat(1 - pow(1 - progress, 2))
        let top = apexPoint(in: bounds)
        let start = CGPoint(x: launchX * bounds.width, y: bounds.height * 1.02)

        return CGPoint(
            x: start.x + (top.x - start.x) * eased,
            y: start.y + (top.y - start.y) * eased
        )
    }

    /// A cheap, repeatable value from `0..<1` for a spark and a purpose (angle, speed, and so on).
    private func hash(_ index: Int, salt: Double) -> Double {
        let value = sin(Double(index) * 12.9898 + salt * 78.233 + seed) * 43_758.5453
        return value - value.rounded(.down)
    }

    private static func shell(inSlot slot: Int, index: Int, configuration: FireworksConfiguration) -> FireworkShell? {
        let mix = (UInt64(slot) &* 0x9E37_79B9_7F4A_7C15) ^ (UInt64(index) &* 0xBF58_476D_1CE4_E5B9)
        var generator = SeededGenerator(seed: configuration.seed ^ mix)

        guard Double.random(in: 0...1, using: &generator) < configuration.launchProbability else { return nil }

        let launchTime = (Double(slot) + Double.random(in: 0..<1, using: &generator)) * configuration.slotLength

        let roll = Double.random(in: 0...1, using: &generator)
        let kind: FireworkKind = roll < 0.5 ? .peony : (roll < 0.75 ? .ring : .willow)

        let launchX = CGFloat.random(in: 0.15...0.85, using: &generator)
        let apex = CGPoint(
            x: launchX + CGFloat.random(in: -0.08...0.08, using: &generator),
            y: CGFloat.random(in: 0.16...0.42, using: &generator)
        )

        // Willows are always gold. Other shells get any hue, with an accent that is either a neighbour or a contrast.
        let hue = kind == .willow ? 0.11 : Double.random(in: 0...1, using: &generator)
        let shift = Bool.random(using: &generator) ? 0.5 : 0.12
        let accentHue = kind == .willow ? hue : (hue + shift).truncatingRemainder(dividingBy: 1)

        return FireworkShell(
            launchTime: launchTime,
            kind: kind,
            launchX: launchX,
            apex: apex,
            hue: hue,
            accentHue: accentHue,
            seed: Double.random(in: 0...1_000, using: &generator)
        )
    }
}
