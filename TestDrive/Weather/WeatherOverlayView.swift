//
//  WeatherOverlayView.swift
//  TestDrive
//

import SwiftUI

/// Shows the weather effect chosen in a ``WeatherViewModel``, crossfading when the effect or intensity changes.
struct WeatherOverlayView: View {
    private let viewModel: WeatherViewModel

    // MARK: - Initializer

    /// Creates the overlay.
    /// - Parameter viewModel: The source of the selected effect and intensities.
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
                // The id gives each intensity a fresh view so the old one fades out instead of jumping.
                SnowfallView(configuration: viewModel.snowIntensity.configuration)
                    .id(viewModel.snowIntensity)
                    .transition(.opacity)
            case .rain:
                RainfallView(configuration: viewModel.rainIntensity.configuration)
                    .id(viewModel.rainIntensity)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: viewModel.effect)
        .animation(.easeInOut(duration: 0.6), value: viewModel.snowIntensity)
        .animation(.easeInOut(duration: 0.6), value: viewModel.rainIntensity)
    }
}

#Preview {
    WeatherOverlayView(viewModel: WeatherViewModel())
        .background(.indigo)
}
