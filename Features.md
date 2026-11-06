# Features

## Invite Friends Screen (UI mock)
A UI-only recreation of the Fetch "Invite friends" screen: purple header with hero illustration, points stats, invite code, View code / Share actions, and a filterable referral list. All data is mocked.

## Snowfall Overlay
A realistic, dependency-free snow effect that overlays any SwiftUI view (`SnowfallView`).

Architectural decisions:
- **Approach:** a single SwiftUI `Canvas` driven by `TimelineView(.animation)`. Chosen over `CAEmitterLayer` (very fast, but emitted particles can't be altered and it needs a UIKit bridge, so wind and depth parallax are hard to control) and SpriteKit (a full game engine for a simple overlay).
- **Performance:** three sprites rasterized once and stamped per flake; softness is baked into radial gradients (no per-frame blur); flake position is a pure function of time, so nothing is mutated or allocated per frame.
- **Realism:** depth layers with parallax speed and size, a shared irregular wind that near flakes feel more, and per-flake flutter.
- **Accessibility:** pauses under Reduce Motion, ignores hit-testing, hidden from VoiceOver.
- **Blizzard:** on top of more and faster flakes, a sustained sideways wind (`windDrift`, felt more by near flakes) and a pulsing white haze (`hazeOpacity`) give the driven, whiteout look. Gentle and Medium have neither.

## Rainfall Overlay
A dependency-free rain effect (`RainfallView`) built the same way as snow: `Canvas` + `TimelineView`, positions as a pure function of time.

Architectural decisions:
- **Drawing:** drops are bucketed into three depth layers and each layer is stroked as one batched `Path`, so the cost is three draw calls per frame regardless of drop count. Sprites would be wasteful here because rain is thin streaks, not round blobs.
- **Realism:** parallax (far drops thin, faint, and slower; near drops thick, bright, and fast), streak length proportional to speed, a wind slant, and slight sky dimming that grows with intensity.
- **Lightning (Downpour only):** deterministic strikes from time slots seeded per slot (`LightningStrike`), so nothing is scheduled or stored. Each strike is a flickering set of pulses that brightens the sky plus a jagged, branching bolt drawn with stacked strokes instead of a blur. Skipped under Reduce Motion because flashing light can be harmful.

## Weather Picker
A segmented control (`WeatherPickerView`) to choose Off / Snow / Rain, plus an intensity control that changes with the effect:
- Snow: Gentle, Medium, Blizzard
- Rain: Sprinkle, Regular, Downpour

Each effect remembers its own intensity, and the overlay crossfades between selections.
