//
//  WeatherEffect.swift
//  TestDrive
//

/// Which effect overlay is showing: weather, or a celebration.
enum WeatherEffect: String, CaseIterable, Identifiable {
    case off = "Off"
    case snow = "Snow"
    case rain = "Rain"
    case confetti = "Confetti"
    case fireworks = "Fireworks"

    var id: String { rawValue }

    /// The SF Symbol that represents this effect.
    var symbolName: String {
        switch self {
        case .off: "cloud"
        case .snow: "snowflake"
        case .rain: "cloud.heavyrain.fill"
        case .confetti: "party.popper.fill"
        case .fireworks: "sparkles"
        }
    }
}
