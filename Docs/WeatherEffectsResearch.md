# Snow and weather effects: goals, methods and Apple's private VFX framework

Branch: `snowfall-effect`. App: `TestDrive` (a test bed, not a shipping app).

## 1. What we are trying to do

1. Build a **constant, performant snow effect** and compare every reasonable way of making one, side by side, in one
   app (Snow > Implementation in the effects menu).
2. Find out **what Apple's own Weather app does** for its animated backgrounds, as far as can be learned from the files
   on this Mac and the simulator runtimes.
3. Go one step further and **call Apple's private engine directly**, loading the Weather app's own scene, to see exactly
   what it does (the "Weather VFX" tab). This is for testing only and is never meant to ship.

Everything below is private API or reverse engineering of system files for learning. None of Apple's assets are copied
into this repository: scenes are read in place from the system at runtime.

## 2. The snow implementations

All of them take the same Gentle / Medium / Blizzard settings (`SnowfallConfiguration`) and, except the first, the same
five depth bands (`SnowLayerStyle`). Size (2 to 14 pt), speed (22 to 112 pt/s), opacity and wind response come from the
same formulas as the Canvas snow (`SnowFlake`), and the sprites are the Canvas snow's own `SnowSprite` gradients. The
GPU and emitter versions put the **softest sprite on far flakes and the sharpest on near flakes**, the opposite of the
Canvas snow.

| Engine | Technique | API | Folder | CPU the user measured |
|---|---|---|---|---|
| SwiftUI Canvas | One `Canvas` in a `TimelineView`; each flake's position is a closed-form function of time; builds a snow pile and haze | public | `Snowfall/` | 13% |
| Emitter Behaviors | `CAEmitterLayer` per depth band, gravity plus `DragBehavior` for a steady fall speed, `WaveBehavior` for sway | public emitter + **private** `CAEmitterBehavior` (via the EmitterBehaviors package, 1.0.0) | `EmitterSnow/` | about 1% |
| CAML Scene | Bundled `.caml` files (XML) describing five `CAEmitterLayer`s with wave and drag behaviors, loaded with `CAPackage` | **private** `CAPackage` | `CAMLSnow/`, `Scripts/generate_snow_caml.py` | not measured |
| Metal Shader | A procedural fragment shader through SwiftUI `colorEffect`; no particles; each pixel hashes its grid cell to decide if it is a flake | public | `MetalSnow/` (`SnowfallShader.metal`) | 8% |
| Metal Instanced | The Canvas flakes uploaded once to a GPU buffer; a vertex shader evaluates the position formula per instance; one instanced draw per frame in an `MTKView` | public | `MetalSnow/` (`InstancedSnow.metal`) | 5% |
| SpriteKit | One `SKEmitterNode` per band in a transparent `SpriteView`, pre-warmed with `advanceSimulationTime` | public | `SpriteKitSnow/` | 8% |
| Weather VFX tab | Apple's own Weather scene through the private VFX engine (section 4) | **private** | `WeatherVFX/` | not measured |

The CPU figures are the user's own readings of the Xcode gauge, with an unknown build configuration and device, so they
are only roughly comparable. They show the app process only: the emitter and CAML approaches do their work in the
render server, so their real cost is GPU and render-server time, which needs Instruments to see.

Not included on purpose: RealityKit's `ParticleEmitterComponent`. It is the public face of the same engine Weather uses
(see section 4) but is 3D-oriented, and there are forum reports of position bugs on iOS 26.1 and later.

### Techniques worth remembering

- **Gravity plus drag, not initial velocity.** With emitter behaviors attached, a cell's own `velocity` did not move the
  flakes. `yAcceleration = speed * drag` with a `DragBehavior(drag)` gives a steady fall speed of `speed`.
- **`CAEmitterCell` reads image pixels as points** unless `contentsScale` is set, so a 3x image drew 3x too big.
- **Pre-warming:** set the emitter layer's `beginTime` to `now - lifetime` so it is already snowing on appearance.
- **Depth of field is baked into the sprite**, as iMessage confetti does for its background pieces, never a layer filter.
- **Density from physics:** birth rate = flakes on screen x speed / screen height, scaled up when the emitter is widened
  to cover wind drift.
- **Metal shader time:** pass elapsed seconds, not a `Date`, so a 32-bit float keeps its precision.

## 3. What Apple's Weather app does (evidence from this Mac)

Found by inspecting `/System/Applications/Weather.app` and the frameworks it links, on macOS 27.2 (the Catalyst build,
Weather 6.0). Method: `otool -L`, `dyld_info -exports` (works on the dyld shared cache), `strings` on bundled `.metallib`
and `.vfxbin` files, and directory listings. Nothing was decoded beyond names and strings.

- **Before iOS 15** the backgrounds were Core Animation Markup Language (`.caml`) files with `CAEmitterLayer` particle
  systems and tiled scrolling cloud images (from the third-party repo `iamvinny/weather-app`, which reads them from the
  app bundle; the repo does not redistribute them).
- **Today** the Weather app links `VFX.framework` and uses scene packages inside `WeatherUI.framework`:
  - `WeatherV136_Default_Background.vfx` (about 5 MB, 99 assets): clouds, sun, stars, rain, snow, sleet, hail, wind and
    lightning, all in one scene.
  - `WeatherV136_Default_Collision.vfx` (72 KB, 4 assets): snow, rain and hail foreground particles plus six box
    colliders (A to F). These are almost certainly the weather cards, so snow can hit the UI.
  - About 263 shared cloud textures (`*_POS.ktx` and `*_NEG.ktx` pairs, 36 MB total, lit by the sun angle).
  - `ForegroundEffectShaders.metallib` with `droplets_fragment` and `frost_fragment` (rain on glass and frost).
- **Snow is two particle layers**, `SnowBG` and `SnowFG`, plus an optional `SnowFast`, drawn as textured quads from
  sprite sheets (`Snow_Sheet.ktx` and friends, ASTC textures of about 240 x 120).
- The same scene name appears in the iOS 26.4 and 26.5 simulator runtimes and on macOS 27.2.

## 4. The private VFX framework

`VFX.framework` (version 16.0, build 233.40.3, built with an internal macOS 27.2 SDK) is not just a particle library. It
exports 146 Objective-C classes and about 2,450 symbols and looks like a full Apple 3D engine whose names mirror
SceneKit's:

- **Scene graph and rendering:** `VFXScene`, `VFXWorld`, `VFXNode`, `VFXView` (a `UIView` with a Metal layer and a
  display link), `VFXRenderer`, `VFXRenderGraph`, `VFXCamera`, `VFXLight`, `VFXMaterial`, `VFXModel`, `VFXMesh`.
- **Camera effects:** bloom, depth of field, motion blur, lens blur, tone mapping, color grading, grain, vignetting.
- **Physics and constraints:** `VFXPhysicsWorld`, bodies, joints, and look-at, billboard and IK constraints.
- **Particles:** `VFXParticleEmitter`, `VFXParticleCollider`, `VFXForceField`.
- **Bridges:** `VFXRE...` classes (`VFXREScene`, `VFXREREnderer`) suggest a link to RealityKit's engine, and the framework
  ships a scene named `com.apple.realitykit.vfx.general`. So RealityKit's public particle emitter is very likely the
  public face of this engine (inference only).
- **GPU compute for particles** (names from `default.metallib`): `particle_integrate`, `particle_force`,
  `particle_force_field`, `particle_update_life`, `particle_compact_data`, `particle_cull`, `particle_update_counters`,
  and colliders (plane, box, sphere, cylinder, mesh, SDF, ray-traced). The simulation is entirely on the GPU.
- Also present: ray-probe global illumination (`vfx_ddgi_update`), skinning, bezier curve rendering, radix sort, and SPH
  fluid and voxel helpers.

It is private: no public headers, and the binary lives in the dyld shared cache. It is reachable on iOS 27 and later (a
device or simulator) and on a Mac as a "Designed for iPad" app, where the frameworks are under `/System/iOSSupport`.
The iOS 26 simulators carry the same files but fail to load the scene with `MTLLibraryErrorDomain: This library is using
language version 4.1 which is not supported on this OS`.

### How we call it (no headers, no linking)

1. **Load the frameworks by path** with `Bundle(path:)?.load()`, trying `/System/iOSSupport/...` first and then
   `/System/Library/...` (`VFXRuntime`). No private symbol is linked.
2. **Discover the API at runtime.** A throwaway test hosted in the app (run on the Mac as Designed for iPad) dumped every
   class's methods with the Objective-C runtime (`class_copyMethodList` and type encodings). That is how the entry points
   below were found.
3. **Load a scene:** `VFXScene -initWithContentsOf:error:` with the `.vfx` package URL, called through a typed
   `@convention(c)` function pointer from `method(for:)`. (`VFXWorld +worldWithURL:` expects a different, SceneKit-style
   `world.plist` format and fails on these packages.)
4. **Show it:** create a `VFXView` (`NSClassFromString("VFXView")`, `init(frame:)`) and `setValue(scene, forKey: "scene")`.
   It renders with Metal on its own display link.
5. **Read and write parameters.** The scene exposes about 278 named parameters (`bindings`), almost all on an object
   called `MAIN`, such as `snowFGParticleCount` (default 700), `snowBGParticleCount` (1000), `snowFGParticleVelocity`
   (78), `snowFGNoiseFieldIntensity` (12), `FallAngle` (30), `useSnowFast` (true), `lightningCloudFlashProbability`
   (0.5). Reading works with `parameterOf:named:`. **Writing with `NSNumber` is rejected** (`Bindings.swift: invalid
   type! trying to set a __NSCFNumber ... of type Float`), because the framework checks the Swift type. The working
   route is `withPointerToParameterOf:named:block:`, which gives a block a raw pointer to the value's storage, so the
   caller must write the right type (`Float`, `Bool`, `SIMD2<Float>`, `SIMD4<Float>`). That is `VFXSceneHandle`.
6. **Reference counting is manual** for the scene's `init`: `alloc` returns an owned object and `init` consumes it, so
   the call uses `Unmanaged` for the receiver and result. Letting Swift retain and release around it over-released the
   scene and crashed in the simulator.

`WeatherVFXCondition` turns the parameters into presets (Clear, Sunny, Cloudy, Rain, Storm, Snow, Sleet, Hail) by
choosing which particle counts are non-zero, using the scene's own defaults.

### What does not work

- `VFXRenderer`'s headless snapshot (`_createSnapshotWithSize:error:`) returns a fully transparent image, and
  `VFXView.snapshot` returns nil. The live view is the only way to see the output (simulator screenshots work).
- `fetchEntityObjectWithTag:` returned nil for every name tried.
- The sun flare, halo and some star dots stay visible whatever the particle counts are, and `restart` does not clear
  them. Other parameters (for example `sunIrisOpacity`, `lightSunIntensity`) have not been tried.

## 5. Open problems (as of this writing)

1. **White flashing on the iOS 27.2 simulator.** Sampling screenshots shows the scene area alternating between its normal
   brightness and pure white (11 to 14 of 18 frames white). It is **not** caused by: preferred frame rate (30 and 60
   tried), render scale, precipitation intensity, the condition (Clear, Cloudy, Snow), or any of our parameter writes
   (it still happens with every write skipped, i.e. Apple's untouched default scene). The scene is loaded once, so it
   is not repeated loading. The cause is still unknown. It may be a simulator Metal issue, or something about how the
   `VFXView` is hosted.
2. **Memory crash on a real iPhone.** `com.apple.vfx.runtime-thread: EXC_RESOURCE (RESOURCE_TYPE_MEMORY: high watermark
   memory limit exceeded) (limit=3376 MB)`. The assets are small (the background scene is 4.9 MB of compressed
   textures), so asset size alone does not explain 3.4 GB. Not yet diagnosed. Hypotheses to test: per-frame render
   target or buffer growth, the full-screen resolution at 3x, particle buffer allocation, or an interaction with the host
   view. Needs a memory graph or Instruments (Allocations, Metal) on the device.
3. **Sun and stars cannot be turned off** (above).
4. **iOS 26 simulators cannot load the scene** (Metal language 4.1). The tab shows an explanatory message there.

Temporary experiment hooks are still in the code and are marked `TEMP`: launch options `-vfxCondition`, `-vfxIntensity`,
`-vfxFPS`, `-vfxScale1`, `-vfxSkipCounts`, `-vfxSkipLightning`, `-vfxSkipAngle`, and a scene load counter in
`VFXSceneHandle`. Remove them when the investigation ends.

## 6. How to run and test

- **Tab shortcut:** launch with `-tab weatherVFX` to open straight onto the Weather VFX tab.
- **Where it runs:** iOS 27 device or simulator, or the Mac as "Designed for iPad". Destinations used:
  `platform=iOS Simulator,id=<iOS 27.2 device>` and `platform=macOS,arch=arm64,variant=Designed for iPad,id=<Mac id>`.
- **The first VFX frame is slow** (10 to 15 seconds in the simulator) while shaders compile, so a screenshot taken too
  early is blank.
- **Tests (Swift Testing):** `GPUSnowTests` (shader parameter packing, Swift and Metal struct layouts, the bundled `.caml`
  files loading through `CAPackage`), `SnowLayerStyleTests`, `WeatherVFXTests` (preset logic, plus runtime tests that load
  the real scene and are skipped before iOS 27). Because the shared scheme has no test action, a private
  `TestDriveTests` scheme lives in the git-ignored `xcuserdata`.
- **Regenerate the CAML scenes:** `python3 Scripts/generate_snow_caml.py`.

## 7. Risks and ground rules

- Private APIs (`CAEmitterBehavior`, `CAPackage`, the whole VFX stack) can break on any OS update and would likely be
  rejected by App Review. Use only in test builds.
- Do not copy Apple's scenes or textures into the project or repository. Read them from the system at runtime.
- Writing the wrong type through a raw pointer corrupts memory. Use the typed setters on `VFXSceneHandle` with the right
  type for each parameter.

## 8. Suggested next steps

1. Diagnose the flashing and the device memory use: attach Instruments (Allocations and Metal System Trace) on the iPhone,
   and try hosting the `VFXView` in a plain `UIViewController` to rule out SwiftUI.
2. Load the lightweight **Collision** scene (72 KB, snow, rain and hail only) instead of the full Background scene, to see
   whether the memory use comes from the Background scene.
3. Find the parameters that control the sun and stars, or discover how Weather sets up a condition before the first frame.
4. Profile all engines in Release on a device for total CPU, GPU and render-server cost.
5. Build a Metal compute particle engine that copies Apple's pipeline (integrate, force field, collide, compact) as a
   public-API alternative.

## 9. Follow-up investigation (November 16, 2026)

Inspection of the installed WeatherUI binary went beyond symbol names: `dyld_info -disassemble` located
`WeatherVFXView.makeUIView` and `VFXView.setupView(with:)`. Their calls were resolved against the loaded framework.
Weather loads a package using `VFXScene.init(options:)` followed by `addEffect(from:)`, supplies WeatherUI's
`default.metallib`, and presents the resulting **effect** with `setEffect:`, rather than presenting a raw scene.
Its setup also explicitly calls `setLowLatency:false` on a child view's **CAMetalLayer**. The similarly named property
on VFXView is separate.

A confirmed loader bug: the simulator could see `/System/iOSSupport` on the host Mac, and our previous Mac-first search
selected those assets while dyld loaded the simulator's VFX binary. Identical scene filenames do not establish binary
compatibility. The loader now restricts simulator resources to `SIMULATOR_ROOT`, devices to their system frameworks,
and iOS-on-Mac/Catalyst to iOSSupport. It does not fall back from a simulator to host assets. The earlier Metal 4.1
failure on iOS 26 must be rechecked with matching resources before treating it as a definitive OS limitation; the
existing iOS 27 availability gate remains in place pending that check.

The implementation now uses the effect-loading/presentation path, reads and writes parameters on that effect, and
applies the child Metal-layer setting. It also defers scene loading until appearance, pauses when hidden/backgrounded
or Reduce Motion is enabled, detaches the effect on view dismantling, and starts with a 30 fps, 1x drawable budget.
The temporary scene-load counter was removed; the remaining launch switches are still available for investigation.

Verification limits: the old path produced 14 pure-white frames out of 18 sampled frames. A run with platform-matched
resources and the old raw-scene presentation exposed runaway memory use in the simulator (31.9 GB peak physical
footprint in a process sample); that run was stopped. This does **not** prove the completed effect/layer/lifecycle
changes resolve either symptom. Subsequent Xcode builds aborted with exit 134 and CoreSimulatorService became
unavailable, preventing a final live regression run. The WeatherVFX sources and regression tests passed standalone
Swift compiler checks, and all seven condition tests passed in a standalone Swift Testing runner. Runtime tests and
sustained frame/memory sampling are still required with the final changes,
including a device run. No Apple scene, texture, shader, or binary was copied into the repository.
