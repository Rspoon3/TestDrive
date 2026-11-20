//
//  WeatherVFXViewModel.swift
//  TestDrive
//

import Foundation

/// Owns Apple's Weather scene and applies the chosen condition and settings to it.
///
/// Every change is written straight into the live scene, so the `VFXView` that shows it updates immediately.
@MainActor
@Observable
final class WeatherVFXViewModel {

    /// The Weather scene package this screen loads.
    static let sceneName = "WeatherV136_Default_Background"

    /// The loaded scene, or `nil` when the private VFX engine isn't available on this system.
    private(set) var scene: VFXSceneHandle?

    private(set) var hasAttemptedLoading = false
    private var isPaused = true

    /// The preset being shown.
    private(set) var condition: WeatherVFXCondition = .snow

    /// Scales precipitation, where `1` is the scene's own amount.
    private(set) var intensity: Float = 1

    /// Whether lightning flashes and bolts are on.
    private(set) var isLightningEnabled = false

    /// The direction particles fall, in degrees. The scene's default is 30.
    private(set) var fallAngle: Float = 30

    // MARK: - Initializer

    /// Configures the controls. Loading waits until the tab appears.
    init() {
        // TEMP experiment options.
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "vfxCondition"), let c = WeatherVFXCondition(rawValue: raw) { condition = c }
        if defaults.object(forKey: "vfxIntensity") != nil { intensity = defaults.float(forKey: "vfxIntensity") }
        isLightningEnabled = condition.hasLightning
    }

    // MARK: - Public Helpers

    /// Loads at most once per tab lifetime, rather than during SwiftUI view initialization.
    func loadSceneIfNeeded() {
        guard !hasAttemptedLoading else { return }
        hasAttemptedLoading = true
        scene = VFXSceneHandle(sceneNamed: Self.sceneName)
        scene?.setPaused(true)
        applyEverything()
        scene?.setPaused(isPaused)
    }

    /// Whether the scene loaded.
    var isAvailable: Bool {
        scene != nil
    }

    /// Switches the condition. Lightning follows the condition's default.
    /// - Parameter newCondition: The preset to show.
    func setCondition(_ newCondition: WeatherVFXCondition) {
        condition = newCondition
        isLightningEnabled = newCondition.hasLightning
        applyEverything()
    }

    /// Changes how much precipitation falls.
    /// - Parameter newIntensity: A multiplier on the scene's own amount. `1` is the default.
    func setIntensity(_ newIntensity: Float) {
        intensity = newIntensity
        applyCounts()
    }

    /// Turns lightning on or off.
    /// - Parameter isEnabled: Whether lightning should strike.
    func setLightningEnabled(_ isEnabled: Bool) {
        isLightningEnabled = isEnabled
        applyLightning()
    }

    /// Changes the direction particles fall.
    /// - Parameter degrees: The angle in degrees. The scene's default is 30.
    func setFallAngle(_ degrees: Float) {
        fallAngle = degrees
        scene?.setFloat(degrees, named: "FallAngle")
    }

    /// Pauses or resumes the scene, for Reduce Motion.
    /// - Parameter isPaused: Whether to pause.
    func setPaused(_ isPaused: Bool) {
        self.isPaused = isPaused
        scene?.setPaused(isPaused)
    }

    // MARK: - Private Helpers

    private func applyEverything() {
        let d = UserDefaults.standard // TEMP bisect switches
        if !d.bool(forKey: "vfxSkipCounts") { applyCounts() }
        if !d.bool(forKey: "vfxSkipLightning") { applyLightning() }
        if !d.bool(forKey: "vfxSkipAngle") { scene?.setFloat(fallAngle, named: "FallAngle") }
    }

    /// Writes every particle count for the current condition.
    private func applyCounts() {
        let names = WeatherVFXCondition.precipitationParameters
            + WeatherVFXCondition.cloudParameters
            + WeatherVFXCondition.starParameters
            + WeatherVFXCondition.sunParameters
            + WeatherVFXCondition.ambientParameters

        for name in names {
            scene?.setFloat(condition.count(for: name, intensity: intensity), named: name)
        }
    }

    /// Turns the scene's lightning on or off by setting how likely and how thick it is.
    private func applyLightning() {
        let isOn = isLightningEnabled

        scene?.setFloat(isOn ? 0.75 : 0, named: "lightningScreenFlashProbability", object: "Lightning")
        scene?.setFloat(isOn ? 0.09 : 0, named: "lightningThickness", object: "Lightning")
        scene?.setFloat(isOn ? 0.5 : 0, named: "lightningCloudFlashProbability")
    }
}
