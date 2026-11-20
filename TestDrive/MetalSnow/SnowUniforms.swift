//
//  SnowUniforms.swift
//  TestDrive
//

import simd

/// The per-frame values the instanced Metal renderer passes to its vertex shader.
///
/// The layout must match `SnowUniforms` in `InstancedSnow.metal`.
struct SnowUniforms {
    /// The size of the area the snow falls through, in points.
    var viewSize: SIMD2<Float>

    /// Seconds since the snowfall started.
    var time: Float

    /// Maximum horizontal travel of the shared wind, in points.
    var windStrength: Float

    /// Sustained sideways speed of the wind, in points per second.
    var windDrift: Float
}
