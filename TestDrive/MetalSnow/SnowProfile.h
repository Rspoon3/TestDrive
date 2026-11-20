//
//  SnowProfile.h
//  TestDrive
//
//  Shared by the Metal snow shaders.
//

#ifndef SnowProfile_h
#define SnowProfile_h

#include <metal_stdlib>
using namespace metal;

/// The opacity of a flake at a normalized radius, where 0 is the center and 1 is the edge.
///
/// These are the gradient stops of the Swift `SnowSprite` views, so a flake drawn on the GPU is as soft as the one the
/// Canvas and emitter snow use. `kind` is the sprite's raw value: 0 is the softest (bokeh), 1 is medium, 2 is the
/// sharpest.
inline float snowProfile(float t, int kind) {
    if (t >= 1.0) {
        return 0.0;
    }

    if (kind == 0) {
        return t < 0.5 ? mix(0.85, 0.35, t / 0.5) : mix(0.35, 0.0, (t - 0.5) / 0.5);
    }

    if (kind == 1) {
        return t < 0.45 ? mix(1.0, 0.75, t / 0.45) : mix(0.75, 0.0, (t - 0.45) / 0.55);
    }

    return t < 0.6 ? 1.0 : mix(1.0, 0.0, (t - 0.6) / 0.4);
}

/// A well-mixed 32-bit integer hash.
inline uint snowHashBits(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352du;
    x ^= x >> 15;
    x *= 0x846ca68bu;
    x ^= x >> 16;
    return x;
}

/// A repeatable random number from 0 to 1 for a grid cell. Use a different `salt` for each value you need.
inline float snowRandom(int2 cell, uint salt) {
    uint bits = uint(cell.x) * 73856093u ^ uint(cell.y) * 19349663u ^ (salt * 83492791u + 0x9e3779b9u);
    return float(snowHashBits(bits)) / 4294967295.0;
}

#endif
