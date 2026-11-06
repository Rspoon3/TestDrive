//
//  RainfallConfiguration.swift
//  TestDrive
//

import CoreGraphics

/// Tunable parameters for a ``RainfallView``.
struct RainfallConfiguration: Equatable {
    /// Total number of drops across all depth layers.
    var dropCount: Int = 200

    /// Multiplier applied to every drop's fall speed.
    var speedMultiplier: CGFloat = 1

    /// How far the wind leans the rain, in degrees from vertical.
    var slantDegrees: CGFloat = 10

    /// How much the sky darkens behind the rain, from `0...1`.
    var dimming: Double = 0.1

    /// Whether the storm throws lightning.
    var hasLightning = false

    /// Seed used to generate the drops and the lightning schedule, so the same configuration always looks the same.
    var seed: UInt64 = 2026

    /// The slant in radians.
    var slantRadians: CGFloat { slantDegrees * .pi / 180 }

    /// A light, sparse shower.
    static let sprinkle = RainfallConfiguration(
        dropCount: 60,
        speedMultiplier: 0.8,
        slantDegrees: 4,
        dimming: 0.04
    )

    /// A steady rain.
    static let regular = RainfallConfiguration()

    /// A heavy, wind-driven storm.
    static let downpour = RainfallConfiguration(
        dropCount: 450,
        speedMultiplier: 1.25,
        slantDegrees: 18,
        dimming: 0.22,
        hasLightning: true
    )
}
