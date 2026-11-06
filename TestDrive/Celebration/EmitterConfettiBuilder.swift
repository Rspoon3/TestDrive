//
//  EmitterConfettiBuilder.swift
//  TestDrive
//

import UIKit

/// Builds the Core Animation emitter layers for ``EmitterConfettiView``.
///
/// This follows the structure of the Fetch app's confetti, using public API only:
/// - **Cannon blast:** a foreground and a background emitter layer (the background one is half size and half opaque,
///   for depth), each firing small rectangles and dots in the brand palette from above the top of the screen. The
///   layer's birth rate animates from 1 to 0 over a second, which makes it a burst, and a keyframe animation ramps
///   gravity up so the pieces hang for a moment and then fall away.
/// - **Rain:** one emitter along a line above the screen, firing a mix of shapes straight down.
///
/// Fetch also pushes pieces around with `CAEmitterBehavior` wave and attractor forces, which are private API loaded by
/// name at runtime. Those are left out here. A keyframed sideways acceleration stands in for the horizontal wave.
@MainActor
struct EmitterConfettiBuilder {
    private enum Shape: CaseIterable {
        case rectangle
        case circle
        case triangle
        case diamond

        var size: CGSize {
            switch self {
            case .rectangle: CGSize(width: 10, height: 6)
            case .circle: CGSize(width: 6, height: 6)
            case .triangle, .diamond: CGSize(width: 8, height: 8)
            }
        }
    }

    private let style: ConfettiStyle
    private let displayScale: CGFloat

    // MARK: - Initializer

    /// Creates a builder.
    /// - Parameters:
    ///   - style: How the confetti arrives.
    ///   - displayScale: The screen scale, so the generated particle images are sharp.
    init(style: ConfettiStyle, displayScale: CGFloat) {
        self.style = style
        self.displayScale = displayScale
    }

    // MARK: - Public Helpers

    /// Creates the emitter layers for the style.
    /// - Parameter bounds: The area the confetti fills.
    /// - Returns: Layers ready to be added to a view's layer.
    func makeLayers(in bounds: CGRect) -> [CAEmitterLayer] {
        switch style {
        case .cannonBlast:
            [cannonLayer(in: bounds, isBackground: false), cannonLayer(in: bounds, isBackground: true)]
        case .rain:
            [rainLayer(in: bounds)]
        }
    }

    // MARK: - Private Helpers

    private func cannonLayer(in bounds: CGRect, isBackground: Bool) -> CAEmitterLayer {
        let layer = CAEmitterLayer()
        layer.frame = bounds
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.minY - 100)
        layer.emitterSize = CGSize(width: 100, height: 100)
        layer.emitterShape = .sphere
        layer.beginTime = CACurrentMediaTime()

        // The model value is 0 and the animation runs 1 to 0, so the layer fires for one second and then stops.
        layer.birthRate = 0

        var cells: [CAEmitterCell] = []
        for shape in [Shape.rectangle, .circle] {
            for (index, color) in ConfettiPalette.uiColors.enumerated() {
                let name = "cannon-\(isBackground ? "back" : "front")-\(shape)-\(index)"
                cells.append(cannonCell(named: name, shape: shape, color: color, isBackground: isBackground))
            }
        }
        layer.emitterCells = cells

        let burst = CABasicAnimation(keyPath: "birthRate")
        burst.duration = 1
        burst.fromValue = 1
        burst.toValue = 0
        layer.add(burst, forKey: "birthRate")

        for cell in cells {
            addMotion(to: layer, cellNamed: cell.name ?? "")
        }

        if isBackground {
            layer.opacity = 0.5
            layer.speed = 0.95
        }

        return layer
    }

    private func cannonCell(named name: String, shape: Shape, color: UIColor, isBackground: Bool) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.name = name
        cell.contents = image(for: shape, color: color)
        cell.contentsScale = displayScale
        cell.beginTime = 0.1
        cell.birthRate = 12
        cell.lifetime = 10
        cell.velocity = 420
        cell.velocityRange = 300
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi * 0.9
        cell.spin = 4
        cell.spinRange = 8
        cell.scale = isBackground ? 0.5 : 1
        cell.scaleRange = 0.2
        return cell
    }

    private func rainLayer(in bounds: CGRect) -> CAEmitterLayer {
        let layer = CAEmitterLayer()
        layer.emitterPosition = CGPoint(x: bounds.width * 0.5, y: -bounds.height * 0.25)
        layer.emitterShape = .line
        layer.emitterSize = CGSize(width: bounds.width, height: bounds.height * 0.2)
        layer.renderMode = .backToFront

        // Seven mixed shapes. Fetch uses image assets here; these are drawn so no files are needed.
        let looks: [(Shape, Int)] = [
            (.rectangle, 0), (.rectangle, 1), (.circle, 5), (.triangle, 2), (.diamond, 7), (.rectangle, 3), (.circle, 8)
        ]
        let birthRate: Float = 30

        layer.emitterCells = looks.map { shape, colorIndex in
            let cell = CAEmitterCell()
            cell.contents = image(for: shape, color: ConfettiPalette.uiColors[colorIndex])
            cell.contentsScale = displayScale
            cell.birthRate = birthRate / Float(looks.count)
            cell.beginTime = CACurrentMediaTime() + Double.random(in: 0..<1)
            cell.lifetime = 15
            cell.velocity = 200
            cell.velocityRange = 20
            cell.emissionLongitude = .pi
            cell.spinRange = 20
            cell.scale = 1
            cell.scaleRange = 0.3
            return cell
        }

        return layer
    }

    /// Ramps gravity up and sways the piece sideways, so confetti hangs for a moment and then falls away.
    private func addMotion(to layer: CAEmitterLayer, cellNamed name: String) {
        let gravity = CAKeyframeAnimation(keyPath: "emitterCells.\(name).yAcceleration")
        gravity.duration = 6
        gravity.keyTimes = [0, 0.1, 0.5, 1]
        gravity.values = [0, 100, 2_000, 4_000]
        layer.add(gravity, forKey: "emitterCells.\(name).yAcceleration")

        let sway = CAKeyframeAnimation(keyPath: "emitterCells.\(name).xAcceleration")
        sway.duration = 3
        sway.repeatCount = 2
        sway.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        sway.values = [0, 160, -160, 120, -120, 0]
        layer.add(sway, forKey: "emitterCells.\(name).xAcceleration")
    }

    private func image(for shape: Shape, color: UIColor) -> CGImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = displayScale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: shape.size, format: format)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: shape.size)
            context.cgContext.setFillColor(color.cgColor)

            switch shape {
            case .rectangle:
                context.cgContext.fill(rect)
            case .circle:
                context.cgContext.fillEllipse(in: rect)
            case .triangle:
                context.cgContext.move(to: CGPoint(x: rect.midX, y: rect.minY))
                context.cgContext.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                context.cgContext.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                context.cgContext.fillPath()
            case .diamond:
                context.cgContext.move(to: CGPoint(x: rect.midX, y: rect.minY))
                context.cgContext.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                context.cgContext.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                context.cgContext.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
                context.cgContext.fillPath()
            }
        }
        .cgImage
    }
}
