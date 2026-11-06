//
//  FireworkKind.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// The kinds of shell, each with its own burst pattern and physics.
enum FireworkKind: CaseIterable {
    /// A round burst of sparks flying out in every direction, denser toward the edge.
    case peony

    /// Sparks flung out at one speed, so they form a clean circle.
    case ring

    /// Slow golden sparks that droop and linger, like a weeping willow.
    case willow

    /// The longest any kind's sparks last, used to know how far back in time to look for live shells.
    static let longestSparkLifetime = FireworkKind.allCases.map(\.sparkLifetime).max() ?? 0

    /// How many sparks the burst throws.
    var sparkCount: Int {
        switch self {
        case .peony: 90
        case .ring: 64
        case .willow: 72
        }
    }

    /// Launch speed of the sparks, in points per second.
    var sparkSpeed: Double {
        switch self {
        case .peony: 420
        case .ring: 360
        case .willow: 300
        }
    }

    /// Air resistance. With the speed it sets how big the burst gets.
    var drag: CGFloat {
        switch self {
        case .peony: 2.6
        case .ring: 2.4
        case .willow: 2
        }
    }

    /// Downward pull on the sparks, in points per second squared.
    var gravity: CGFloat {
        switch self {
        case .peony: 70
        case .ring: 60
        case .willow: 140
        }
    }

    /// How long the sparks last, in seconds.
    var sparkLifetime: TimeInterval {
        switch self {
        case .peony, .ring: 1.9
        case .willow: 3.2
        }
    }

    /// How far back in time each spark's streak reaches, in seconds. Longer means a longer tail.
    var trailLength: TimeInterval {
        switch self {
        case .peony, .ring: 0.06
        case .willow: 0.14
        }
    }

    /// Stroke width of a spark, in points.
    var lineWidth: CGFloat {
        switch self {
        case .peony: 1.8
        case .ring: 2
        case .willow: 1.5
        }
    }

    /// How rich the color is, from `0...1`. Willows are a paler gold.
    var saturation: Double {
        switch self {
        case .peony: 0.85
        case .ring: 0.8
        case .willow: 0.55
        }
    }
}
