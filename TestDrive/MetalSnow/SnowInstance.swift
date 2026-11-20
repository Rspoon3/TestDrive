//
//  SnowInstance.swift
//  TestDrive
//

import Foundation

/// One flake as the instanced Metal renderer reads it.
///
/// The layout must match `SnowInstance` in `InstancedSnow.metal`: ten tightly packed floats.
struct SnowInstance: Equatable {
    var startX: Float
    var startY: Float
    var size: Float
    var opacity: Float
    var speed: Float
    var swayAmplitude: Float
    var swayFrequency: Float
    var swayPhase: Float
    var windFactor: Float
    var spriteKind: Float

    // MARK: - Initializer

    /// Creates an instance from a Canvas snow flake.
    ///
    /// The Canvas snow puts its crisp sprite on distant flakes. To match the other GPU snow views, far flakes get the
    /// softest sprite here and near flakes the sharpest, so the sprite kind is flipped.
    /// - Parameter flake: The flake to copy.
    init(_ flake: SnowFlake) {
        startX = Float(flake.startX)
        startY = Float(flake.startY)
        size = Float(flake.size)
        opacity = Float(flake.opacity)
        speed = Float(flake.speed)
        swayAmplitude = Float(flake.swayAmplitude)
        swayFrequency = Float(flake.swayFrequency)
        swayPhase = Float(flake.swayPhase)
        windFactor = Float(flake.windFactor)
        spriteKind = Float(SnowSprite.far.rawValue - flake.spriteIndex)
    }

    // MARK: - Public Helpers

    /// Builds the instances for a configuration, far to near.
    /// - Parameter configuration: The snowfall parameters.
    /// - Returns: One instance per flake, in the order the Canvas snow draws them.
    static func makeInstances(for configuration: SnowfallConfiguration) -> [SnowInstance] {
        SnowFlake.makeFlakes(for: configuration).map(SnowInstance.init)
    }
}
