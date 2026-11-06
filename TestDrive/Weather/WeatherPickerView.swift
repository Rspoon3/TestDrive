//
//  WeatherPickerView.swift
//  TestDrive
//

import SwiftUI

/// Segmented controls for choosing the weather effect and its intensity.
struct WeatherPickerView: View {
    @Bindable private var viewModel: WeatherViewModel

    // MARK: - Initializer

    /// Creates the picker.
    /// - Parameter viewModel: The model the selections are written to.
    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            Picker("Weather", selection: $viewModel.effect) {
                ForEach(WeatherEffect.allCases) { effect in
                    Text(effect.rawValue).tag(effect)
                }
            }

            switch viewModel.effect {
            case .off:
                EmptyView()
            case .snow:
                Picker("Snow intensity", selection: $viewModel.snowIntensity) {
                    ForEach(SnowIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }
            case .rain:
                Picker("Rain intensity", selection: $viewModel.rainIntensity) {
                    ForEach(RainIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }
            }
        }
        .pickerStyle(.segmented)
        .padding(16)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .padding(.horizontal, 16)
        .animation(.default, value: viewModel.effect)
    }
}

#Preview {
    WeatherPickerView(viewModel: WeatherViewModel())
}
