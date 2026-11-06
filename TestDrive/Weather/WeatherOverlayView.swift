//
//  WeatherOverlayView.swift
//  TestDrive
//

import SwiftUI

/// Shows the effect chosen in a ``WeatherViewModel``, crossfading when the effect changes.
struct WeatherOverlayView: View {
    private let viewModel: WeatherViewModel

    // MARK: - Initializer

    /// Creates the overlay.
    /// - Parameter viewModel: The source of the selected effect and its settings.
    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.effect {
            case .off:
                EmptyView()
            case .snow:
                // No id here: the same view keeps running when the intensity changes, so the flakes can land on one
                // continuous pile. The view eases the new flakes in itself.
                SnowfallView(configuration: viewModel.snowIntensity.configuration, pile: viewModel.snowPile)
                    .transition(.opacity)
            case .rain:
                RainfallView(configuration: viewModel.rainIntensity.configuration)
                    .id(viewModel.rainIntensity)
                    .transition(.opacity)
            case .confetti:
                confetti
                    .id(viewModel.celebrationID)
            case .fireworks:
                FireworksView(configuration: viewModel.fireworksIntensity.configuration)
                    .id(viewModel.celebrationID)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.effect)
        .animation(.easeInOut(duration: 0.6), value: viewModel.rainIntensity)
    }

    // MARK: - Private Views

    @ViewBuilder
    private var confetti: some View {
        switch viewModel.confettiEngine {
        case .coreAnimation:
            EmitterConfettiView(style: viewModel.confettiStyle)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        case .canvas:
            CanvasConfettiView(style: viewModel.confettiStyle)
        }
    }
}

#Preview {
    WeatherOverlayView(viewModel: WeatherViewModel())
        .background(.indigo)
}
