//
//  WeatherViewModel.swift
//  TestDrive
//

import SwiftUI

/// Holds which effect is showing, how each one is set up, and the snow pile.
///
/// Each effect remembers its own settings, so switching from snow to rain and back keeps your choice. The snow pile
/// survives intensity changes but starts fresh each time snow begins. Confetti and fireworks restart from the
/// beginning whenever they are chosen, changed, or replayed.
@MainActor
@Observable
final class WeatherViewModel {
    /// The active overlay.
    private(set) var effect: WeatherEffect = .snow

    /// The remembered snow intensity.
    private(set) var snowIntensity: SnowIntensity = .medium

    /// The remembered rain intensity.
    private(set) var rainIntensity: RainIntensity = .regular

    /// Which implementation draws the confetti.
    private(set) var confettiEngine: ConfettiEngine = .coreAnimation

    /// How the confetti arrives.
    private(set) var confettiStyle: ConfettiStyle = .cannonBlast

    /// The remembered fireworks show size.
    private(set) var fireworksIntensity: FireworksIntensity = .show

    /// The snow bank that flakes build along the bottom edge.
    private(set) var snowPile = SnowPile()

    /// Changes whenever a celebration should start over. The overlay uses it as the view's identity, which is what
    /// makes SwiftUI build a fresh confetti or fireworks view.
    private(set) var celebrationID = UUID()

    // MARK: - Public Helpers

    /// Switches the active effect. Starting snow starts a new, empty pile, and starting a celebration starts it over.
    /// - Parameter newEffect: The effect to show.
    func setEffect(_ newEffect: WeatherEffect) {
        guard newEffect != effect else { return }

        effect = newEffect

        switch newEffect {
        case .snow:
            snowPile = SnowPile()
        case .confetti, .fireworks:
            replay()
        case .off, .rain:
            break
        }
    }

    /// Changes how hard it snows. The pile keeps what has built up.
    /// - Parameter intensity: The new snow intensity.
    func setSnowIntensity(_ intensity: SnowIntensity) {
        snowIntensity = intensity
    }

    /// Changes how hard it rains.
    /// - Parameter intensity: The new rain intensity.
    func setRainIntensity(_ intensity: RainIntensity) {
        rainIntensity = intensity
    }

    /// Changes which implementation draws the confetti, and plays it again.
    /// - Parameter engine: The new engine.
    func setConfettiEngine(_ engine: ConfettiEngine) {
        confettiEngine = engine
        replay()
    }

    /// Changes how the confetti arrives, and plays it again.
    /// - Parameter style: The new style.
    func setConfettiStyle(_ style: ConfettiStyle) {
        confettiStyle = style
        replay()
    }

    /// Changes the fireworks show size, and starts the show over.
    /// - Parameter intensity: The new show size.
    func setFireworksIntensity(_ intensity: FireworksIntensity) {
        fireworksIntensity = intensity
        replay()
    }

    /// Starts the current celebration over.
    func replay() {
        celebrationID = UUID()
    }
}
