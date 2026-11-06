//
//  RainfallView.swift
//  TestDrive
//

import SwiftUI

/// A realistic, GPU-friendly rainfall that can be overlaid on any screen.
///
/// How it stays fast: drops are bucketed into three depth layers, and each layer is drawn as a single batched `Path`
/// with one stroke. That is three draw calls per frame no matter how many drops there are. Positions are a pure
/// function of time, so nothing is mutated or allocated per frame beyond the paths.
///
/// How it looks real: faster, thicker, brighter drops in front and thin faint ones behind (parallax), streak length
/// that follows speed, a wind slant, and a slight darkening of the sky.
struct RainfallView: View {
    private static let dropColor = Color(red: 0.86, green: 0.92, blue: 1)
    private static let flashColor = Color(red: 0.82, green: 0.89, blue: 1)

    private let configuration: RainfallConfiguration
    private let layers: [[RainDrop]]

    @State private var startDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates a rainfall.
    /// - Parameter configuration: Controls drop count, speed, slant, and sky dimming.
    init(configuration: RainfallConfiguration = .regular) {
        self.configuration = configuration

        let drops = RainDrop.makeDrops(for: configuration)
        layers = (0..<RainDrop.layerCount).map { layer in
            drops.filter { $0.layer == layer }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.opacity(configuration.dimming)

            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let elapsed = timeline.date.timeIntervalSince(startDate)

                Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                    drawDrops(in: &context, size: size, elapsed: elapsed)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Private Helpers

    /// Strokes each depth layer as one batched path.
    private func drawDrops(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        // Lightning goes first so the rain is drawn in front of it, as if lit from behind.
        // It is skipped under Reduce Motion because flashing light can be harmful.
        if configuration.hasLightning, !reduceMotion {
            drawLightning(in: &context, size: size, elapsed: elapsed)
        }

        let slant = configuration.slantRadians
        let dx = sin(slant)
        let dy = cos(slant)

        for (index, drops) in layers.enumerated() {
            var path = Path()

            for drop in drops {
                let head = drop.position(at: elapsed, in: size, slantRadians: slant)
                path.move(to: CGPoint(x: head.x - dx * drop.length, y: head.y - dy * drop.length))
                path.addLine(to: head)
            }

            context.stroke(
                path,
                with: .color(Self.dropColor.opacity(RainDrop.opacities[index])),
                style: StrokeStyle(lineWidth: RainDrop.lineWidths[index], lineCap: .round)
            )
        }
    }

    /// Lights the sky and draws the bolt for the current strike, if one is flashing.
    ///
    /// The glow is a few progressively thinner strokes, not a blur, so it stays cheap. When no strike is flashing this
    /// returns immediately.
    private func drawLightning(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        guard let strike = LightningStrike.strike(at: elapsed, seed: configuration.seed) else { return }

        let intensity = strike.intensity(at: elapsed)
        guard intensity > 0.01 else { return }

        // The whole sky brightens, most at the top where the cloud is.
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [
                    Self.flashColor.opacity(0.8 * intensity),
                    Self.flashColor.opacity(0.35 * intensity)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        let bolt = strike.boltPaths(in: size)
        let glow: [(width: CGFloat, opacity: Double)] = [(34, 0.18), (16, 0.3), (7, 0.55)]

        for layer in glow {
            context.stroke(
                bolt.main,
                with: .color(Self.flashColor.opacity(layer.opacity * intensity)),
                style: StrokeStyle(lineWidth: layer.width, lineCap: .round, lineJoin: .round)
            )
        }

        context.stroke(
            bolt.main,
            with: .color(.white.opacity(intensity)),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )

        context.stroke(
            bolt.branches,
            with: .color(Self.flashColor.opacity(0.4 * intensity)),
            style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
        )

        context.stroke(
            bolt.branches,
            with: .color(.white.opacity(0.9 * intensity)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        RainfallView(configuration: .downpour)
    }
}
