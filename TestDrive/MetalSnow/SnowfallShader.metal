//
//  SnowfallShader.metal
//  TestDrive
//
//  A procedural snowfall for SwiftUI's `colorEffect`. There is no particle list: every pixel works out which grid cell
//  it is in, hashes the cell to get a flake's size, position and flutter, and draws it if the pixel falls inside.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
#include "SnowProfile.h"
using namespace metal;

/// The number of floats that describe one depth layer in `parameters`. Keep in sync with `SnowShaderParameters`.
constant int snowFloatsPerLayer = 7;

/// The number of floats before the layers in `parameters`.
constant int snowFloatsInHeader = 2;

/// Draws falling snow.
///
/// `parameters` is `[windStrength, windDrift]` followed by seven floats per depth layer, far to near:
/// `[size, sizeRange, speed, opacity, windFactor, spriteKind, flakeCount]`.
[[ stitchable ]] half4 snowfall(
    float2 position,
    half4 color,
    float4 bounds,
    float time,
    device const float *parameters,
    int parameterCount
) {
    float2 viewSize = bounds.zw;
    float windStrength = parameters[0];
    float windDrift = parameters[1];
    int layerCount = (parameterCount - snowFloatsInHeader) / snowFloatsPerLayer;

    // Two slow, unrelated sines make an irregular gust shared by every flake.
    float gust = sin(time * 0.21) + 0.4 * sin(time * 0.53 + 1.3);

    float alpha = 0.0;

    for (int layer = 0; layer < layerCount; layer++) {
        device const float *p = parameters + snowFloatsInHeader + layer * snowFloatsPerLayer;
        float flakeSize = p[0];
        float sizeRange = p[1];
        float speed = p[2];
        float opacity = p[3];
        float windFactor = p[4];
        int kind = int(p[5]);
        float flakeCount = max(p[6], 1.0);

        // One flake per grid cell, with the cell sized so about `flakeCount` flakes are on screen.
        float cellSize = sqrt(viewSize.x * viewSize.y / flakeCount);

        // The whole grid moves with the wind and falls, so a pixel samples the grid where the flakes were.
        float2 sample = position;
        sample.x -= gust * windStrength * windFactor + windDrift * windFactor * time;
        sample.y -= speed * time;

        int2 cell = int2(floor(sample / cellSize));
        float2 local = sample - float2(cell) * cellSize;
        uint salt = uint(layer) * 16u;

        float size = flakeSize + (snowRandom(cell, salt + 1u) * 2.0 - 1.0) * sizeRange;
        float radius = size * 0.5;

        // Closer flakes flutter more. The sway is limited so the flake never leaves its own cell.
        float depth = clamp((windFactor - 0.3) / 0.7, 0.0, 1.0);
        float margin = radius + 1.0;
        float swayLimit = max(cellSize * 0.5 - margin, 0.0);
        float swayAmplitude = min(4.0 + depth * 22.0 + snowRandom(cell, salt + 2u) * 6.0, swayLimit * 0.75);
        float frequency = 0.5 + snowRandom(cell, salt + 3u) * 1.1;
        float phase = snowRandom(cell, salt + 4u) * 6.2831853;
        float flutter = sin(time * frequency + phase) + 0.3 * sin(time * frequency * 2.3 + phase * 1.7);

        float freeX = max(cellSize - 2.0 * (margin + swayAmplitude), 0.0);
        float freeY = max(cellSize - 2.0 * margin, 0.0);
        float2 center = float2(
            cellSize * 0.5 + (snowRandom(cell, salt + 5u) - 0.5) * freeX + flutter * swayAmplitude * 0.5,
            cellSize * 0.5 + (snowRandom(cell, salt + 6u) - 0.5) * freeY
        );

        float t = distance(local, center) / max(radius, 0.001);
        float flakeAlpha = snowProfile(t, kind) * opacity;

        // Layers run far to near, so each one is composited over the last (premultiplied "over").
        alpha = flakeAlpha + alpha * (1.0 - flakeAlpha);
    }

    return half4(half(alpha));
}
