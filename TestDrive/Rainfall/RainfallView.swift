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
                let tail = CGPoint(x: head.x - dx * drop.length, y: head.y - dy * drop.length)
                let ground = drop.groundY(in: size)

                // Once the tail is below the ground the whole streak has landed.
                guard tail.y < ground else { continue }

                // Clip the streak where it meets the ground, so it shortens into the ground instead of falling through.
                var end = head
                if head.y > ground {
                    let overshoot = (head.y - ground) / dy
                    end = CGPoint(x: head.x - dx * overshoot, y: ground)
                }

                path.move(to: tail)
                path.addLine(to: end)
            }

            context.stroke(
                path,
                with: .color(Self.dropColor.opacity(RainDrop.opacities[index])),
                style: StrokeStyle(lineWidth: RainDrop.lineWidths[index], lineCap: .round)
            )
        }

        drawSplashes(in: &context, size: size, elapsed: elapsed)
    }

    /// Draws a flat ring and a few bouncing droplets wherever a drop has just hit the ground.
    ///
    /// Splashes are batched into four paths (rings and droplets, each bright while young and dim while fading), so the
    /// cost is four draw calls however many drops are landing.
    private func drawSplashes(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        guard configuration.splashFraction > 0 else { return }

        let slant = configuration.slantRadians

        // A faint wet sheen along the ground, stronger in heavier rain.
        let sheenHeight: CGFloat = 90
        context.fill(
            Path(CGRect(x: 0, y: size.height - sheenHeight, width: size.width, height: sheenHeight)),
            with: .linearGradient(
                Gradient(colors: [Self.dropColor.opacity(0), Self.dropColor.opacity(0.12 * configuration.splashFraction)]),
                startPoint: CGPoint(x: 0, y: size.height - sheenHeight),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        var brightRings = Path()
        var dimRings = Path()
        var brightDroplets = Path()
        var dimDroplets = Path()

        for (layer, drops) in layers.enumerated() {
            let scale = RainDrop.splashScales[layer]

            for drop in drops where drop.splashRoll < configuration.splashFraction {
                guard let splash = drop.splash(at: elapsed, in: size, slantRadians: slant) else { continue }

                let progress = CGFloat(splash.age / RainDrop.splashLifetime)
                let isYoung = progress < 0.45

                // The ring: a flat ellipse, because we see the ground at a shallow angle, that grows as it fades.
                let radius = (2 + 9 * progress) * scale
                let ring = CGRect(x: splash.x - radius, y: splash.y - radius * 0.3, width: radius * 2, height: radius * 0.6)

                if isYoung {
                    brightRings.addEllipse(in: ring)
                } else {
                    dimRings.addEllipse(in: ring)
                }

                // Three droplets thrown up and out, then pulled back down by gravity.
                let age = CGFloat(splash.age)
                let lift = -(110 + CGFloat(splash.variation) * 60) * scale

                for index in 0..<3 {
                    let sideways = (CGFloat(index - 1) * 26 + CGFloat(splash.variation - 0.5) * 16) * scale
                    let x = splash.x + sideways * age
                    let y = splash.y + lift * age + 450 * age * age

                    // Back on the ground, so the droplet is gone.
                    guard y <= splash.y else { continue }

                    let radius = 1.1 * scale
                    let droplet = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)

                    if isYoung {
                        brightDroplets.addEllipse(in: droplet)
                    } else {
                        dimDroplets.addEllipse(in: droplet)
                    }
                }
            }
        }

        context.stroke(brightRings, with: .color(Self.dropColor.opacity(0.5)), lineWidth: 0.8)
        context.stroke(dimRings, with: .color(Self.dropColor.opacity(0.2)), lineWidth: 0.8)
        context.fill(brightDroplets, with: .color(Self.dropColor.opacity(0.85)))
        context.fill(dimDroplets, with: .color(Self.dropColor.opacity(0.4)))
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
