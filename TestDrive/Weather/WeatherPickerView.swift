//
//  WeatherPickerView.swift
//  TestDrive
//

import SwiftUI

/// A round button that opens a menu for choosing the effect and its settings.
///
/// The button's icon follows the current effect, and the menu below the effect list changes to match it.
struct WeatherPickerView: View {
    private let viewModel: WeatherViewModel

    // MARK: - Initializer

    /// Creates the picker.
    /// - Parameter viewModel: The model the selections are written to.
    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Menu {
            Section("Effect") {
                Picker("Effect", selection: effectSelection) {
                    ForEach(WeatherEffect.allCases) { effect in
                        Label(effect.rawValue, systemImage: effect.symbolName)
                            .tag(effect)
                    }
                }
                .pickerStyle(.inline)
            }

            settings
        } label: {
            Image(systemName: viewModel.effect.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 52, height: 52)
                .background(Color.black.opacity(0.45), in: .circle)
        }
        .accessibilityLabel("Effects")
    }

    // MARK: - Private Views

    @ViewBuilder
    private var settings: some View {
        switch viewModel.effect {
        case .off:
            EmptyView()
        case .snow:
            Section("Snow intensity") {
                Picker("Snow intensity", selection: snowSelection) {
                    ForEach(SnowIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }
                .pickerStyle(.inline)
            }
        case .rain:
            Section("Rain intensity") {
                Picker("Rain intensity", selection: rainSelection) {
                    ForEach(RainIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }
                .pickerStyle(.inline)
            }
        case .confetti:
            Section("Implementation") {
                Picker("Implementation", selection: engineSelection) {
                    ForEach(ConfettiEngine.allCases) { engine in
                        Text(engine.rawValue).tag(engine)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Style") {
                Picker("Style", selection: confettiStyleSelection) {
                    ForEach(ConfettiStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.inline)
            }

            Button { viewModel.replay() } label: {
                Label("Replay", systemImage: "arrow.clockwise")
            }
        case .fireworks:
            Section("Show size") {
                Picker("Show size", selection: fireworksSelection) {
                    ForEach(FireworksIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }
                .pickerStyle(.inline)
            }
        }
    }

    // MARK: - Private Helpers

    private var effectSelection: Binding<WeatherEffect> {
        Binding { viewModel.effect } set: { viewModel.setEffect($0) }
    }

    private var snowSelection: Binding<SnowIntensity> {
        Binding { viewModel.snowIntensity } set: { viewModel.setSnowIntensity($0) }
    }

    private var rainSelection: Binding<RainIntensity> {
        Binding { viewModel.rainIntensity } set: { viewModel.setRainIntensity($0) }
    }

    private var engineSelection: Binding<ConfettiEngine> {
        Binding { viewModel.confettiEngine } set: { viewModel.setConfettiEngine($0) }
    }

    private var confettiStyleSelection: Binding<ConfettiStyle> {
        Binding { viewModel.confettiStyle } set: { viewModel.setConfettiStyle($0) }
    }

    private var fireworksSelection: Binding<FireworksIntensity> {
        Binding { viewModel.fireworksIntensity } set: { viewModel.setFireworksIntensity($0) }
    }
}

#Preview {
    WeatherPickerView(viewModel: WeatherViewModel())
        .padding()
        .background(.indigo)
}
