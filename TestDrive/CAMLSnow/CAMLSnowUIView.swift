//
//  CAMLSnowUIView.swift
//  TestDrive
//

import UIKit

/// A non-interactive view that plays a bundled `.caml` snow scene.
///
/// The scenes (`snow-gentle.caml`, `snow-medium.caml`, `snow-blizzard.caml`) hold everything about the particles:
/// five `CAEmitterLayer`s, their cells, and wave and drag `CAEmitterBehavior`s, all as plain XML. They are authored in a
/// 390 x 844 design space and scaled to fit the view's width. The view only adds what a file can't carry: it draws each
/// cell's sprite, and pre-warms the emitters so snow is already falling.
final class CAMLSnowUIView: UIView {

    /// Which scene to play. Changing it loads a different file.
    var intensity: SnowIntensity = .medium {
        didSet {
            guard intensity != oldValue else { return }
            configuredSize = .zero
            setNeedsLayout()
        }
    }

    /// Whether snow is showing. Turn off to respect Reduce Motion.
    var isEmitting = true {
        didSet { sceneLayer?.isHidden = !isEmitting }
    }

    private var sceneLayer: CALayer?
    private var configuredSize: CGSize = .zero

    /// The size the scene files are authored for, in points.
    private static let designSize = CGSize(width: 390, height: 844)

    // MARK: - Initializer

    /// Creates a snow view.
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width > 0, bounds.height > 0 else { return }

        // Reload only when the size or scene changes.
        guard bounds.size != configuredSize else { return }
        configuredSize = bounds.size
        loadScene()
    }

    // MARK: - Private Helpers

    /// Replaces the current scene with the file for the current intensity.
    private func loadScene() {
        sceneLayer?.removeFromSuperlayer()
        sceneLayer = nil

        guard let root = CAMLPackage.rootLayer(named: sceneName) else {
            print("CAMLSnowUIView: couldn't load \(sceneName).caml. CAPackage may be unavailable.")
            return
        }

        // Fit the design space to the width, anchored at the top-left so snow keeps falling from the top edge.
        let scale = bounds.width / Self.designSize.width
        root.anchorPoint = .zero
        root.position = .zero
        root.bounds = CGRect(origin: .zero, size: Self.designSize)
        root.transform = CATransform3DMakeScale(scale, scale, 1)
        root.isHidden = !isEmitting

        prepareEmitters(in: root)

        layer.addSublayer(root)
        sceneLayer = root
    }

    /// Gives each emitter's cells their sprites and pre-warms the emitter.
    /// - Parameter root: The loaded scene.
    private func prepareEmitters(in root: CALayer) {
        let screenScale = window?.screen.scale ?? traitCollection.displayScale
        let imageScale = screenScale > 0 ? screenScale : 3

        for case let emitter as CAEmitterLayer in root.sublayers ?? [] {
            let cells = emitter.emitterCells ?? []

            for cell in cells {
                // Cells are named `flake0` ... `flake4`, matching the index of the depth band.
                guard
                    let name = cell.name,
                    let index = Int(name.dropFirst("flake".count)),
                    SnowLayerStyle.all.indices.contains(index)
                else { continue }

                cell.contents = SnowFlakeImage.make(sprite: SnowLayerStyle.all[index].sprite, scale: imageScale)
                cell.contentsScale = imageScale
            }

            emitter.emitterCells = cells

            // Pre-warm so the screen is already snowing when the scene appears.
            let longestLifetime = cells.map(\.lifetime).max() ?? 0
            emitter.beginTime = CACurrentMediaTime() - CFTimeInterval(longestLifetime)
        }
    }

    /// The bundled file for the current intensity.
    private var sceneName: String {
        switch intensity {
        case .gentle: "snow-gentle"
        case .medium: "snow-medium"
        case .blizzard: "snow-blizzard"
        }
    }
}
