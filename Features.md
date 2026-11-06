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
- **Snow pile:** flakes really land. `SnowPile` is a height map; each frame it checks which flakes crossed the surface since the last frame (flakes are pure functions of time, so "where was it a frame ago" is just another call) and adds snow there, spread over three columns. Slopes steeper than snow's angle of repose slump sideways so the bank settles into mounds. Landed flakes stop being drawn, and the bank is drawn in the same `Canvas` as the flakes. Heavier snow builds it faster on its own; `depositScale` evens out the extremes. The pile is owned by the view model so it survives intensity changes, and starts fresh each time snow begins. This is the only mutable state, so the canvas renders synchronously on the main thread.

## Rainfall Overlay
A dependency-free rain effect (`RainfallView`) built the same way as snow: `Canvas` + `TimelineView`, positions as a pure function of time.

Architectural decisions:
- **Drawing:** drops are bucketed into three depth layers and each layer is stroked as one batched `Path`, so the cost is three draw calls per frame regardless of drop count. Sprites would be wasteful here because rain is thin streaks, not round blobs.
- **Realism:** parallax (far drops thin, faint, and slower; near drops thick, bright, and fast), streak length proportional to speed, a wind slant, and slight sky dimming that grows with intensity.
- **Splashes:** drops land on a ground plane (far drops land higher up the screen, near drops at the bottom edge, which gives the ground depth) and the streak shortens into the ground as it lands. Each landing throws a flat ring and three droplets that arc up and fall back. Like everything else, splashes are a pure function of time: a drop's landing times and the age of its current splash fall out of the same arithmetic as its position. They are batched into four draw calls (rings and droplets, young and fading). `splashFraction` sets how many drops splash and how wet the ground looks: a quarter for Sprinkle, 60% for Regular, all of them for Downpour.
- **Lightning (Downpour only):** deterministic strikes from time slots seeded per slot (`LightningStrike`), so nothing is scheduled or stored. Each strike is a flickering set of pulses that brightens the sky plus a jagged, branching bolt drawn with stacked strokes instead of a blur. Skipped under Reduce Motion because flashing light can be harmful.

## Weather Picker
A round menu button (`WeatherPickerView`) in the top right, next to the screen's edit button. Its icon follows the current effect. The menu chooses Off / Snow / Rain, plus an intensity list that changes with the effect:
- Snow: Gentle, Medium, Blizzard
- Rain: Sprinkle, Regular, Downpour

Each effect remembers its own intensity, and the overlay crossfades between selections.

## Confetti (two implementations)
Both support the same styles (Cannon blast, Rain) and share one palette, and you pick between them in the effects menu so they can be compared side by side. Both are dependency-free.

- **Core Animation (`EmitterConfettiView`)**: modelled on the approach in the Fetch app, with public API only. `CAEmitterLayer` emitters: for the cannon blast, a foreground layer and a half-size, half-opacity background layer fire small rectangles and dots from above the top of the screen. The layer's birth rate animates 1 to 0 over a second, which makes it a burst, and a keyframe animation ramps gravity so pieces hang and then fall away. Rain is a line emitter above the screen. Fetch also uses private `CAEmitterBehavior` wave and attractor forces, loaded by name at runtime. Those are deliberately left out, and a keyframed sideways acceleration stands in for the wave. Particle images are drawn in code instead of loaded from assets.
- **SwiftUI Canvas (`CanvasConfettiView`)**: every piece is a pure function of time, like the snow and rain. Pieces fly out of two bottom-corner cannons (or fall from above for rain) under drag and gravity (`DragMotion`), so they leave fast, slow within a second, and drift down at a paper-like terminal speed, with sway, spin, and a tumble that squashes the piece and swaps to a darker shade for its back. Pieces are batched into one path per color and facing, so a frame is at most 18 fills.

Both are skipped under Reduce Motion.

## Fireworks
A Canvas fireworks show (`FireworksView`) over a darkened sky. Shells (`FireworkShell`) are launched from time slots seeded per slot, so the show is endless and reproducible with nothing stored. Three kinds: peony (round burst), ring, and willow (gold, drooping). A rocket climbs with an eased tail, then bursts into sparks whose motion is solved in closed form with drag and gravity (`DragMotion`), so each spark's angle and speed come from a cheap hash of its index. Sparks are drawn as short streaks with additive blending, batched into a few paths per shell by color and brightness, with a flash at the moment of the burst. Show size: Sparse, Show, Finale. Skipped under Reduce Motion because it flashes.
