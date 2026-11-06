//
//  RainIntensity.swift
//  TestDrive
//

/// How hard it is raining.
enum RainIntensity: String, CaseIterable, Identifiable {
    case sprinkle = "Sprinkle"
    case regular = "Regular"
    case downpour = "Downpour"

    var id: String { rawValue }

    /// The rainfall parameters for this intensity.
    var configuration: RainfallConfiguration {
        switch self {
        case .sprinkle: .sprinkle
        case .regular: .regular
        case .downpour: .downpour
        }
    }
}
