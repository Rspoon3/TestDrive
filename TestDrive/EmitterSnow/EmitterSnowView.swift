//
//  EmitterSnowView.swift
//  TestDrive
//

import SwiftUI

/// A full-bleed, constantly falling snow effect built from `CAEmitterLayer`s and `EmitterBehaviors`.
///
/// The `SwiftUI Canvas` snow (`SnowfallView`) is the dependency-free counterpart. Both take a
/// ``SnowfallConfiguration`` and are tuned to match in flake size, speed and density, so they can be compared. Unlike
/// the Canvas version there is no snow pile or blizzard haze.
///
/// Place it in a `ZStack` above your background. It ignores touches, so content underneath stays interactive.
struct EmitterSnowView: UIViewRepresentable {
    private let configuration: SnowfallConfiguration

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates the snow.
    /// - Parameter configuration: How much snow falls, how fast, and how windy it is.
    init(configuration: SnowfallConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> SnowEmitterUIView {
        let view = SnowEmitterUIView()
        view.configuration = configuration
        view.isEmitting = !reduceMotion
        return view
    }

    func updateUIView(_ uiView: SnowEmitterUIView, context: Context) {
        uiView.configuration = configuration
        uiView.isEmitting = !reduceMotion
    }
}

#Preview {
    ZStack {
        Color.black
        EmitterSnowView()
    }
    .ignoresSafeArea()
}
