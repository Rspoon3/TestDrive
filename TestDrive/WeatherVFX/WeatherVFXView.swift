//
//  WeatherVFXView.swift
//  TestDrive
//

import SwiftUI
import QuartzCore

/// Apple's private `VFXView`, showing a loaded Weather scene.
///
/// The view renders with Metal on its own display link, so nothing here drives frames. Parameter changes written to the
/// ``VFXSceneHandle`` show up on the next frame. If the VFX engine isn't available, this is an empty view.
struct WeatherVFXView: UIViewRepresentable {
    private let scene: VFXSceneHandle?

    // MARK: - Initializer

    /// Creates the view.
    /// - Parameter scene: The loaded Weather scene, or `nil` to show nothing.
    init(scene: VFXSceneHandle?) {
        self.scene = scene
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UIView {
        guard let scene, let viewClass = VFXRuntime.viewClass else {
            return UIView()
        }

        let view = viewClass.init(frame: .zero)
        view.isUserInteractionEnabled = false
        // Configure the drawable before attaching an effect, which starts rendering.
        view.contentScaleFactor = 1
        view.setValue(30, forKey: "preferredFramesPerSecond")
        // TEMP experiment options.
        if let fps = UserDefaults.standard.object(forKey: "vfxFPS") as? Int { view.setValue(fps, forKey: "preferredFramesPerSecond") }
        if UserDefaults.standard.bool(forKey: "vfxScale1") { view.contentScaleFactor = 1 }
        view.setValue(scene.effect, forKey: "effect")
        configureMetalLayers(in: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        guard uiView.responds(to: NSSelectorFromString("setEffect:")) else { return }
        uiView.isHidden = true
        uiView.setValue(nil, forKey: "effect")
    }

    /// WeatherUI's setupView(with:) disables low latency on the child view's CAMetalLayer.
    /// VFXView.lowLatency is a separate property and does not configure this layer.
    private func configureMetalLayers(in view: UIView) {
        if let layer = view.layer as? CAMetalLayer,
           layer.responds(to: NSSelectorFromString("setLowLatency:")) {
            layer.setValue(false, forKey: "lowLatency")
        }
        for subview in view.subviews {
            configureMetalLayers(in: subview)
        }
    }
}
