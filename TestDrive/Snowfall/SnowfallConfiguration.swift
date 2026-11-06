//
//  SnowfallConfiguration.swift
//  TestDrive
//

import CoreGraphics

/// Tunable parameters for a ``SnowfallView``.
struct SnowfallConfiguration: Equatable {
    /// Total number of flakes across all depth layers.
    var flakeCount: Int = 140

    /// Multiplier applied to every flake's fall speed. `1` is a calm snowfall.
    var speedMultiplier: CGFloat = 1

    /// Maximum horizontal travel, in points, of the slow shared wind that pushes all flakes left and right.
    var windStrength: CGFloat = 40

    /// Sustained sideways speed, in points per second, of the wind. Unlike ``windStrength`` this is a steady push in
    /// one direction, which is what makes a blizzard look driven instead of just busy.
    var windDrift: CGFloat = 0

    /// Opacity of a pulsing white haze over the scene, from `0...1`. Simulates the whiteout of a blizzard.
    var hazeOpacity: Double = 0

    /// Scales how much each landing flake adds to the pile. More flakes and faster flakes already build it faster,
    /// so this evens things out: light snow is boosted so a pile is still visible, and a blizzard is held back.
    var depositScale: Double = 1

    /// Seed used to generate the flakes, so the same configuration always looks the same.
    var seed: UInt64 = 2026

    /// A light, slow snowfall with barely any wind.
    static let gentle = SnowfallConfiguration(
        flakeCount: 70,
        speedMultiplier: 0.7,
        windStrength: 20,
        depositScale: 2.5
    )

    /// A steady snowfall.
    static let medium = SnowfallConfiguration()

    /// A violent, wind-driven whiteout: a wall of fast flakes blown sideways, under a pulsing haze.
    static let blizzard = SnowfallConfiguration(
        flakeCount: 700,
        speedMultiplier: 2.4,
        windStrength: 200,
        windDrift: 320,
        hazeOpacity: 0.22,
        depositScale: 0.5
    )

    /// The default snowfall.
    static let `default` = medium
}
