//
//  InstancedSnow.metal
//  TestDrive
//
//  Draws every flake as one instance of a quad. Positions are the same closed-form function of time the Canvas snow
//  uses (`SnowFlake.position`), evaluated in the vertex shader, so the CPU does nothing per frame but encode one draw.
//

#include <metal_stdlib>
#include "SnowProfile.h"
using namespace metal;

/// One flake. Keep in sync with the Swift `SnowInstance`.
struct SnowInstance {
    float startX;
    float startY;
    float size;
    float opacity;
    float speed;
    float swayAmplitude;
    float swayFrequency;
    float swayPhase;
    float windFactor;
    float spriteKind;
};

/// Per-frame values shared by every flake. Keep in sync with the Swift `SnowUniforms`.
struct SnowUniforms {
    float2 viewSize;
    float time;
    float windStrength;
    float windDrift;
};

struct SnowVertexOut {
    float4 position [[position]];
    float2 local;
    float opacity;
    float kind [[flat]];
};

vertex SnowVertexOut snowVertex(
    uint vertexID [[vertex_id]],
    uint instanceID [[instance_id]],
    constant SnowInstance *flakes [[buffer(0)]],
    constant SnowUniforms &uniforms [[buffer(1)]]
) {
    SnowInstance flake = flakes[instanceID];
    float time = uniforms.time;

    // Extra room off-screen so flakes enter and leave without popping.
    float margin = flake.size * 2.0 + flake.swayAmplitude + uniforms.windStrength;
    float loopHeight = uniforms.viewSize.y + margin * 2.0;
    float loopWidth = uniforms.viewSize.x + margin * 2.0;

    float fallen = flake.startY * loopHeight + flake.speed * time;
    float y = fmod(fallen, loopHeight) - margin;

    float gust = sin(time * 0.21) + 0.4 * sin(time * 0.53 + 1.3);
    float wind = gust * uniforms.windStrength * flake.windFactor;

    float flutter = sin(time * flake.swayFrequency + flake.swayPhase)
        + 0.3 * sin(time * flake.swayFrequency * 2.3 + flake.swayPhase * 1.7);
    float sway = flutter * flake.swayAmplitude;

    float drift = uniforms.windDrift * flake.windFactor * time;

    float rawX = flake.startX * loopWidth + wind + sway + drift;
    float x = rawX - floor(rawX / loopWidth) * loopWidth - margin;

    // A triangle strip: 0 is (-1, -1), 1 is (1, -1), 2 is (-1, 1), 3 is (1, 1).
    float2 corner = float2((vertexID & 1u) != 0u ? 1.0 : -1.0, (vertexID & 2u) != 0u ? 1.0 : -1.0);
    float2 point = float2(x, y) + corner * flake.size * 0.5;

    SnowVertexOut out;
    out.position = float4(point.x / uniforms.viewSize.x * 2.0 - 1.0, 1.0 - point.y / uniforms.viewSize.y * 2.0, 0.0, 1.0);
    out.local = corner;
    out.opacity = flake.opacity;
    out.kind = flake.spriteKind;
    return out;
}

fragment float4 snowFragment(SnowVertexOut in [[stage_in]]) {
    float alpha = snowProfile(length(in.local), int(in.kind + 0.5)) * in.opacity;

    // Premultiplied white.
    return float4(alpha);
}
