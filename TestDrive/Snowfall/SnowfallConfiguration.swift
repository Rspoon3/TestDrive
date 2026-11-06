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

    /// Seed used to generate the flakes, so the same configuration always looks the same.
    var seed: UInt64 = 2026

    /// A calm default snowfall.
    static let `default` = SnowfallConfiguration()

    /// A heavier, windier snowfall.
    static let blizzard = SnowfallConfiguration(
        flakeCount: 260,
        speedMultiplier: 1.7,
        windStrength: 110
    )
}
