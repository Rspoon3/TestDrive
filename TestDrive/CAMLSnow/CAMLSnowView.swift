//
//  CAMLSnowView.swift
//  TestDrive
//

import SwiftUI

/// A full-bleed snowfall loaded from a bundled Core Animation Markup Language (`.caml`) scene.
///
/// This is how Apple's Weather app described its backgrounds before iOS 15: particles and behaviors live in a data file
/// instead of code. See ``CAMLSnowUIView``. The scenes are fixed per intensity, so this view takes a ``SnowIntensity``
/// and not a configuration. There is no snow pile and no blizzard haze.
struct CAMLSnowView: UIViewRepresentable {
    private let intensity: SnowIntensity

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates the snow.
    /// - Parameter intensity: Which bundled scene to play.
    init(intensity: SnowIntensity = .medium) {
        self.intensity = intensity
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> CAMLSnowUIView {
        let view = CAMLSnowUIView()
        view.intensity = intensity
        view.isEmitting = !reduceMotion
        return view
    }

    func updateUIView(_ uiView: CAMLSnowUIView, context: Context) {
        uiView.intensity = intensity
        uiView.isEmitting = !reduceMotion
    }
}

#Preview {
    ZStack {
        Color.black
        CAMLSnowView()
    }
    .ignoresSafeArea()
}
