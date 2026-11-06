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
