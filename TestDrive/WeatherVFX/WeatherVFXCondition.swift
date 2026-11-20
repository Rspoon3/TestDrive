//
//  WeatherVFXCondition.swift
//  TestDrive
//

/// A weather condition shown by Apple's own Weather scene, as a preset of its parameters.
///
/// The scene (`WeatherV136_Default_Background`) contains every kind of weather at once, each controlled by particle
/// counts, so a condition is a choice of which counts are non-zero. The numbers are the scene's own defaults, which
/// were read back from the loaded scene.
enum WeatherVFXCondition: String, CaseIterable, Identifiable {
    case clear = "Clear"
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    case rain = "Rain"
    case storm = "Storm"
    case snow = "Snow"
    case sleet = "Sleet"
    case hail = "Hail"

    var id: String { rawValue }

    /// The SF Symbol that represents this condition.
    var symbolName: String {
        switch self {
        case .clear: "moon.stars.fill"
        case .sunny: "sun.max.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .snow: "snowflake"
        case .sleet: "cloud.sleet.fill"
        case .hail: "cloud.hail.fill"
        }
    }

    /// Whether lightning is on by default for this condition.
    var hasLightning: Bool {
        self == .storm
    }

    // MARK: - Particle counts

    /// Every particle-count parameter this app controls, so a preset can switch the others off.
    static let precipitationParameters = [
        "rainFGParticleCount", "rainBGParticleCount",
        "sleetFGParticleCount", "sleetBGParticleCount",
        "hailParticleCount",
        "snowFGParticleCount", "snowBGParticleCount"
    ]

    /// The cloud layers' particle counts.
    static let cloudParameters = [
        "cloudFGParticleCount", "cloudFFGParticleCount", "cloudBGParticleCount", "cloudBBGParticleCount"
    ]

    /// The star field's particle counts.
    static let starParameters = ["starParticleCount", "starBrightParticleCount"]

    /// The sun's flare, halo and rays.
    static let sunParameters = ["sunRaysParticleCount", "sunIrisParticleCount", "fringeParticleCount"]

    /// Extra particles (wind streaks, fog puffs, foreground specks) that no condition here uses, so they stay off.
    static let ambientParameters = ["windParticleAmount", "noiseParticleCount", "foregroundParticlesParticleCount"]

    /// The scene's default value for each count, which a preset turns on.
    private static let defaults: [String: Float] = [
        "rainFGParticleCount": 1000, "rainBGParticleCount": 1500,
        "sleetFGParticleCount": 500, "sleetBGParticleCount": 1500,
        "hailParticleCount": 500,
        "snowFGParticleCount": 700, "snowBGParticleCount": 1000,
        "cloudFGParticleCount": 10, "cloudFFGParticleCount": 10,
        "cloudBGParticleCount": 9, "cloudBBGParticleCount": 9,
        "starParticleCount": 1000, "starBrightParticleCount": 133,
        "sunRaysParticleCount": 3, "sunIrisParticleCount": 10, "fringeParticleCount": 12
    ]

    /// The particle count for a parameter in this condition.
    /// - Parameters:
    ///   - name: One of ``precipitationParameters``, ``cloudParameters``, ``starParameters``, ``sunParameters`` or
    ///     ``ambientParameters``.
    ///   - intensity: Scales precipitation only. `1` is the scene's default.
    /// - Returns: The count to write, which is `0` when this condition doesn't use the parameter.
    func count(for name: String, intensity: Float) -> Float {
        let base = Self.defaults[name] ?? 0
        let isPrecipitation = Self.precipitationParameters.contains(name)

        guard isActive(name) else { return 0 }
        return isPrecipitation ? (base * intensity).rounded() : base
    }

    // MARK: - Private Helpers

    private func isActive(_ name: String) -> Bool {
        if Self.starParameters.contains(name) {
            return self == .clear
        }

        if Self.sunParameters.contains(name) {
            return self == .sunny
        }

        if Self.cloudParameters.contains(name) {
            return self != .clear
        }

        switch self {
        case .clear, .sunny, .cloudy:
            return false
        case .rain, .storm:
            return name.hasPrefix("rain")
        case .snow:
            return name.hasPrefix("snow")
        case .sleet:
            return name.hasPrefix("sleet")
        case .hail:
            return name.hasPrefix("hail")
        }
    }
}
