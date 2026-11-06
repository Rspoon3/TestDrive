//
//  FireworksIntensity.swift
//  TestDrive
//

/// How big the fireworks show is.
enum FireworksIntensity: String, CaseIterable, Identifiable {
    case sparse = "Sparse"
    case show = "Show"
    case finale = "Finale"

    var id: String { rawValue }

    /// The fireworks parameters for this intensity.
    var configuration: FireworksConfiguration {
        switch self {
        case .sparse: .sparse
        case .show: .show
        case .finale: .finale
        }
    }
}
