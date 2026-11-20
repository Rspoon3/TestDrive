//
//  WeatherVFXTabView.swift
//  TestDrive
//

import SwiftUI

/// A playground for Apple's own Weather scene, driven through the private `VFX` engine.
///
/// The background is Weather's real `WeatherV136_Default_Background` scene, read in place from the system. Pick a
/// condition, adjust the precipitation, and toggle lightning. Private API for testing only. It needs iOS 27 or later (a
/// device or simulator), or a Mac running the app as "Designed for iPad".
struct WeatherVFXTabView: View {
    @State private var viewModel = WeatherVFXViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isAvailable {
                WeatherVFXView(scene: viewModel.scene)
                    .ignoresSafeArea()

                controls
            } else if viewModel.hasAttemptedLoading {
                unavailable
            } else {
                ProgressView("Loading weather…")
                    .tint(.white)
            }
        }
        .task {
            isVisible = true
            viewModel.loadSceneIfNeeded()
            updatePlayback()
        }
        .onDisappear {
            isVisible = false
            updatePlayback()
        }
        .onChange(of: reduceMotion) { updatePlayback() }
        .onChange(of: scenePhase) { updatePlayback() }
    }

    // MARK: - Private Views

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("Condition", selection: conditionSelection) {
                ForEach(WeatherVFXCondition.allCases) { condition in
                    Label(condition.rawValue, systemImage: condition.symbolName)
                        .tag(condition)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            LabeledContent("Intensity") {
                Slider(value: intensitySelection, in: 0.1...2)
            }

            LabeledContent("Fall angle") {
                Slider(value: fallAngleSelection, in: -45...45)
            }

            Toggle("Lightning", isOn: lightningSelection)
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 20))
        .padding()
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var unavailable: some View {
        ContentUnavailableView(
            "Private VFX unavailable",
            systemImage: "cloud.slash",
            description: Text(
                "Apple's Weather scene needs iOS 27 or later (the iOS 26 simulators can't compile its Metal 4.1 shaders). Run on an iOS 27 device or simulator, or on a Mac as a Designed for iPad app."
            )
        )
        .foregroundStyle(.white)
    }

    // MARK: - Private Helpers

    private func updatePlayback() {
        viewModel.setPaused(!isVisible || scenePhase != .active || reduceMotion)
    }

    private var conditionSelection: Binding<WeatherVFXCondition> {
        Binding { viewModel.condition } set: { viewModel.setCondition($0) }
    }

    private var intensitySelection: Binding<Double> {
        Binding { Double(viewModel.intensity) } set: { viewModel.setIntensity(Float($0)) }
    }

    private var fallAngleSelection: Binding<Double> {
        Binding { Double(viewModel.fallAngle) } set: { viewModel.setFallAngle(Float($0)) }
    }

    private var lightningSelection: Binding<Bool> {
        Binding { viewModel.isLightningEnabled } set: { viewModel.setLightningEnabled($0) }
    }
}

#Preview {
    WeatherVFXTabView()
}
