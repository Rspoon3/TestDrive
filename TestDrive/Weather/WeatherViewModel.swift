//
//  WeatherViewModel.swift
//  TestDrive
//

import SwiftUI

/// Holds which weather effect is showing and how intense each one is.
///
/// Each effect remembers its own intensity, so switching from snow to rain and back keeps your choice.
@MainActor
@Observable
final class WeatherViewModel {
    /// The active weather overlay.
    var effect: WeatherEffect = .snow

    /// The remembered snow intensity.
    var snowIntensity: SnowIntensity = .medium

    /// The remembered rain intensity.
    var rainIntensity: RainIntensity = .regular
}
