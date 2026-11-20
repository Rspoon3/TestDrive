//
//  SnowShaderParameters.swift
//  TestDrive
//

import Foundation

/// Packs a ``SnowfallConfiguration`` into the flat float array the `snowfall` shader reads.
///
/// The layout is `[windStrength, windDrift]` followed by seven floats for each ``SnowLayerStyle``, far to near:
/// `[size, sizeRange, speed, opacity, windFactor, spriteKind, flakeCount]`. Keep it in sync with
/// `SnowfallShader.metal`.
enum SnowShaderParameters {

    /// The number of floats before the layers.
    static let headerCount = 2

    /// The number of floats that describe one layer.
    static let floatsPerLayer = 7

    // MARK: - Public Helpers

    /// Builds the shader's parameter array.
    /// - Parameter configuration: How much snow falls, how fast, and how windy it is.
    /// - Returns: The packed floats, ready for `Shader.Argument.floatArray`.
    static func make(for configuration: SnowfallConfiguration) -> [Float] {
        let flakesPerLayer = Float(configuration.flakeCount) / Float(SnowLayerStyle.bandCount)

        var values: [Float] = []
        values.append(Float(configuration.windStrength))
        values.append(Float(configuration.windDrift))

        for style in SnowLayerStyle.all {
            let speed = Float(style.speed * configuration.speedMultiplier)

            values.append(Float(style.size))
            values.append(Float(style.sizeRange))
            values.append(speed)
            values.append(style.opacity)
            values.append(Float(style.windFactor))
            values.append(Float(style.sprite.rawValue))
            values.append(flakesPerLayer)
        }

        return values
    }
}
