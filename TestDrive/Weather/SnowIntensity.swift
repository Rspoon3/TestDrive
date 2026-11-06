//
//  SnowIntensity.swift
//  TestDrive
//

/// How hard it is snowing.
enum SnowIntensity: String, CaseIterable, Identifiable {
    case gentle = "Gentle"
    case medium = "Medium"
    case blizzard = "Blizzard"

    var id: String { rawValue }

    /// The snowfall parameters for this intensity.
    var configuration: SnowfallConfiguration {
        switch self {
        case .gentle: .gentle
        case .medium: .medium
        case .blizzard: .blizzard
        }
    }
}
