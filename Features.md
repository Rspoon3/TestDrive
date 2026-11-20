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
- Snow: an implementation (SwiftUI Canvas, Emitter Behaviors, CAML Scene, Metal Shader, Metal Instanced, or SpriteKit), then Gentle, Medium, Blizzard
- Rain: Sprinkle, Regular, Downpour

Each effect remembers its own intensity, and the overlay crossfades between selections.

## Confetti (two implementations)
Both support the same styles (Cannon blast, Rain) and share one palette, and you pick between them in the effects menu so they can be compared side by side. Both are dependency-free.

- **Core Animation (`EmitterConfettiView`)**: modelled on the approach in the Fetch app, with public API only. `CAEmitterLayer` emitters: for the cannon blast, a foreground layer and a half-size, half-opacity background layer fire small rectangles and dots from above the top of the screen. The layer's birth rate animates 1 to 0 over a second, which makes it a burst, and a keyframe animation ramps gravity so pieces hang and then fall away. Rain is a line emitter above the screen. Fetch also uses private `CAEmitterBehavior` wave and attractor forces, loaded by name at runtime. Those are deliberately left out, and a keyframed sideways acceleration stands in for the wave. Particle images are drawn in code instead of loaded from assets.
- **SwiftUI Canvas (`CanvasConfettiView`)**: every piece is a pure function of time, like the snow and rain. Pieces fly out of two bottom-corner cannons (or fall from above for rain) under drag and gravity (`DragMotion`), so they leave fast, slow within a second, and drift down at a paper-like terminal speed, with sway, spin, and a tumble that squashes the piece and swaps to a darker shade for its back. Pieces are batched into one path per color and facing, so a frame is at most 18 fills.

Both are skipped under Reduce Motion.

## Fireworks
A Canvas fireworks show (`FireworksView`) over a darkened sky. Shells (`FireworkShell`) are launched from time slots seeded per slot, so the show is endless and reproducible with nothing stored. Three kinds: peony (round burst), ring, and willow (gold, drooping). A rocket climbs with an eased tail (about a third of rockets corkscrew up in a helix with a colored tail, using whole turns so the spiral unwinds exactly at the burst point), then bursts into sparks whose motion is solved in closed form with drag and gravity (`DragMotion`), so each spark's angle and speed come from a cheap hash of its index. Sparks are drawn as short streaks with additive blending, batched into a few paths per shell by color and brightness, with a flash at the moment of the burst. Show size: Sparse, Show, Finale. Skipped under Reduce Motion because it flashes.

## Emitter Snow (EmitterBehaviors)
A second snow implementation, chosen from the effects menu under Snow > Implementation, built with [EmitterBehaviors](https://github.com/Rspoon3/EmitterBehaviors) (`1.0.0`, the project's only package dependency). It is the `CAEmitterLayer` + private `CAEmitterBehavior` counterpart to the dependency-free Canvas snow, and takes the same Gentle / Medium / Blizzard settings. Lives in `TestDrive/EmitterSnow` (`EmitterSnowView`).

Architectural decisions:
- **Matching the Canvas snow:** flake size (2 to 14 pt), fall speed (22 to 112 pt/s), opacity and wind response come from the same formulas as `SnowFlake`, sliced into five depth bands (`SnowLayerStyle`). Each band is its own `CAEmitterLayer`, and its birth rate is solved from the screen height and fall speed so `flakeCount` flakes are on screen at once. Wind drift widens the emitter on the upwind side so the screen stays evenly covered.
- **Falling:** flakes fall under gravity (`yAcceleration`), with `DragBehavior` capping each band at a steady speed (`gravity / drag`). Cell `velocity` is not used.
- **Focus:** the opposite of the Canvas snow: far flakes use its softest sprite and near flakes its sharpest, which still has a soft edge. The sprites are the Canvas snow's own `SnowSprite` views, rendered once with `ImageRenderer`, so softness matches. As in iMessage confetti, the blur is baked into the sprite rather than applied as a layer filter.
- **Motion:** two `WaveBehavior`s (a slow sway and a faster wobble), scaled by the configuration's `windStrength`, add sideways drift. `windDrift` becomes a sideways acceleration.
- **Always snowing:** each emitter's `beginTime` is set in the past (pre-warmed) so flakes are already falling when it appears.
- **Not included:** the snow pile and the blizzard haze, which belong to the Canvas version. Reduce Motion stops emitting.
- **Private API:** `CAEmitterBehavior` is private. If it is missing on an OS, the drift and drag cap silently do nothing, so flakes fall straight down and keep accelerating.

## More Snow Implementations (GPU and data-driven)
Four more engines sit beside Canvas and Emitter Behaviors in the Snow > Implementation menu, so the approaches can be compared on one screen. All take the same Gentle / Medium / Blizzard settings, use the same five depth bands (`SnowLayerStyle`: size 2 to 14 pt, speed 22 to 112 pt/s) and the same sprites (`SnowSprite`), with far flakes soft and near flakes sharper. None of them has the Canvas snow pile or the Blizzard haze. RealityKit's `ParticleEmitterComponent` is deliberately not included: it is 3D-oriented and has reported position bugs on iOS 26.1 and later.

- **CAML Scene** (`TestDrive/CAMLSnow`): the format Apple's Weather app used for its backgrounds before iOS 15. `snow-gentle.caml`, `snow-medium.caml` and `snow-blizzard.caml` hold five `CAEmitterLayer`s each, with their cells and wave and drag `CAEmitterBehavior`s, as plain XML. `CAMLPackage` loads them through the private `CAPackage` class (found by name at runtime, nothing linked), so this engine needs no EmitterBehaviors package. The files are generated by `Scripts/generate_snow_caml.py` from the same formulas as `SnowLayerStyle`, authored in a 390 x 844 design space and scaled to the view's width. Sprites can't live in the files, so `CAMLSnowUIView` assigns each cell's image by name (`flake0` ... `flake4`) and pre-warms the emitters. Private API: nothing is shown if `CAPackage` is missing. Apple's own Weather scenes are not bundled (they are Apple's assets).
- **Metal Shader** (`MetalShaderSnowView`, `SnowfallShader.metal`): a procedural fragment shader applied with SwiftUI's `colorEffect` inside a `TimelineView`. There are no particles: each pixel finds its grid cell, hashes the cell for a flake's size, position and flutter, and draws it if the pixel falls inside. Cost depends on screen pixels and layers, not flake count. Elapsed time (not a date) is passed so the 32-bit float keeps precision.
- **Metal Instanced** (`InstancedSnowView`, `InstancedSnowRenderer`, `InstancedSnow.metal`): the Canvas snow ported to the GPU. The very same flakes (`SnowFlake.makeFlakes`) are uploaded once to a buffer, and a vertex shader evaluates `SnowFlake.position`'s formula per instance, so each frame is one instanced draw in an `MTKView` and the only per-frame CPU input is the time. There is no compute pass because the closed-form position needs no simulation state.
- **SpriteKit** (`SpriteKitSnowView`, `SnowScene`): one `SKEmitterNode` per depth band in a transparent `SpriteView`, pre-warmed with `advanceSimulationTime`. Wind drift tilts the emission angle, and a repeating `particleAction` adds the sway (every particle sways in step, unlike the per-flake flutter elsewhere).

Shared Metal code (`SnowProfile.h`) holds the sprite gradient profiles and the cell hash used by both shaders.

## Weather VFX Tab (Apple's private engine)
A second tab, "Weather VFX", that runs Apple's own Weather scene through the private `VFX` engine, the one the Weather app uses for its animated backgrounds. Private API for testing only, never for shipping.

- **How it loads:** `VFXRuntime` loads `VFX.framework` and `WeatherUI.framework` by path with `Bundle.load()` (no private symbol is linked), then `VFXSceneHandle` creates a `VFXScene` from `WeatherV136_Default_Background.vfx`, which is read in place from `WeatherUI.framework` and never copied into this project. `WeatherVFXView` hosts a `VFXView` and sets its `scene`. The view renders with Metal on its own display link.
- **Parameters:** the scene exposes about 280 named parameters, almost all on an object called `MAIN` (`snowFGParticleCount`, `rainBGParticleCount`, `lightningThickness` ...). The framework type-checks values and rejects `NSNumber`, so they are written straight into the parameter's storage through `withPointerToParameterOf:named:block:`. The caller must use the right type per parameter (`Float`, `Bool`, `SIMD2<Float>`).
- **Conditions:** `WeatherVFXCondition` presets (Clear, Cloudy, Rain, Storm, Snow, Sleet, Hail) choose which particle counts are non-zero, using the scene's own defaults (for example 700 foreground and 1000 background snow particles). Controls: condition, precipitation intensity, fall angle, lightning.
- **Where it runs:** iOS 27 or later (a device or simulator) and a Mac as a "Designed for iPad" app, where the frameworks live under `/System/iOSSupport`. The iOS 26 simulators carry the same `WeatherV136_Default_Background.vfx`, but loading it fails there with "This library is using language version 4.1 which is not supported on this OS", so the tab shows an unavailable message before iOS 27.
- **Tests:** `WeatherVFXTests.swift` has pure preset tests, plus runtime tests that load the real scene and are skipped where the engine is missing.
- **Findings about the engine:** `VFXScene -initWithContentsOf:error:` loads a `.vfx` package. `VFXWorld worldWithURL:` expects a different (SceneKit-style `world.plist`) format. `VFXRenderer`'s headless snapshot and `VFXView.snapshot` return nothing usable, so the only way to see the output is the live view.
- **Reference counting:** `VFXScene`'s `init` consumes the `alloc` reference. `VFXSceneHandle` calls it with `Unmanaged` so Swift doesn't add its own retain and release, which over-released the scene and crashed in the simulator.
- **Known gap:** the sun flare and halo and some star dots stay visible in every condition. They aren't controlled by the particle counts this tab sets (`sunRaysParticleCount`, `sunIrisParticleCount`, `fringeParticleCount`, `starParticleCount`), and restarting the scene doesn't clear them, so other parameters (for example `sunIrisOpacity` or `lightSunIntensity`) still need to be found. Snow, rain, sleet, hail, clouds and lightning respond to the controls.

See `Docs/WeatherEffectsResearch.md` for the full write-up of the goals, methods, findings about Apple's Weather app and its private VFX framework, and the open problems.
