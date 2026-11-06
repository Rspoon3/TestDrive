//
//  SnowfallView.swift
//  TestDrive
//

import SwiftUI

/// A realistic, GPU-friendly snowfall that can be overlaid on any screen.
///
/// How it stays fast:
/// - One `Canvas` draws every flake and the snow bank, so there is no per-flake view or layout.
/// - Flakes are stamped from three sprites that SwiftUI rasterizes once. Softness comes from a radial gradient baked
///   into the sprite, so there are no per-frame blur filters.
/// - Flake positions are a pure function of time (see ``SnowFlake/position(at:in:windStrength:windDrift:)``), so the
///   flakes hold no state. The only mutable state is the ``SnowPile`` height map.
/// - `TimelineView(.animation)` lets the system pick the refresh rate, including ProMotion, and stops when the
///   app is not visible.
///
/// How it looks real: three depth layers (large soft near flakes, crisp tiny far flakes) with parallax speed, a shared
/// wind that near flakes feel more, per-flake flutter, and flakes that land and build a bank along the bottom.
struct SnowfallView: View {
    private let configuration: SnowfallConfiguration
    private let flakes: [SnowFlake]
    private let pile: SnowPile

    @State private var startDate = Date()
    @State private var configurationChangedAt = Date.distantPast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates a snowfall.
    /// - Parameters:
    ///   - configuration: Controls flake count, speed, wind, and haze.
    ///   - pile: The snow bank the flakes land on. Pass the same pile to keep it when the configuration changes.
    init(configuration: SnowfallConfiguration = .default, pile: SnowPile = SnowPile()) {
        self.configuration = configuration
        self.pile = pile
        flakes = SnowFlake.makeFlakes(for: configuration)
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            let fade = fadeIn(at: timeline.date)

            ZStack {
                if configuration.hazeOpacity > 0 {
                    haze(elapsed: elapsed, fade: fade)
                }

                // Drawn synchronously on the main thread because the pile is updated from inside the draw.
                Canvas(opaque: false, rendersAsynchronously: false) { context, size in
                    pile.update(to: elapsed, size: size, flakes: flakes, configuration: configuration)
                    drawFlakes(in: &context, size: size, elapsed: elapsed, fade: fade)
                    drawPile(in: &context, size: size)
                } symbols: {
                    ForEach(SnowSprite.allCases) { sprite in
                        sprite.view
                            .tag(sprite.rawValue)
                    }
                }
            }
        }
        .onChange(of: configuration) {
            configurationChangedAt = .now
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Private Views

    /// A slowly pulsing white veil, denser toward the ground, that sells the whiteout.
    private func haze(elapsed: TimeInterval, fade: Double) -> some View {
        let pulse = 0.8 + 0.2 * sin(elapsed * 0.4)
        let opacity = configuration.hazeOpacity * pulse * fade

        return LinearGradient(
            colors: [.white.opacity(opacity * 0.6), .white.opacity(opacity)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Private Helpers

    /// Eases new flakes in after the intensity changes, so the swap from one set of flakes to the next isn't a hard cut.
    private func fadeIn(at date: Date) -> Double {
        let progress = min(1, date.timeIntervalSince(configurationChangedAt) / 0.8)
        return progress * progress * (3 - 2 * progress)
    }

    /// Stamps every flake that hasn't landed yet onto the canvas.
    private func drawFlakes(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval, fade: Double) {
        // Resolve each sprite once per frame, outside the flake loop.
        let sprites = SnowSprite.allCases.compactMap { context.resolveSymbol(id: $0.rawValue) }
        guard sprites.count == SnowSprite.allCases.count else { return }

        for flake in flakes {
            let center = flake.position(
                at: elapsed,
                in: size,
                windStrength: configuration.windStrength,
                windDrift: configuration.windDrift
            )

            // Below the surface means the flake has landed, so it is part of the pile now.
            guard center.y < pile.surfaceY(atX: center.x, in: size) else { continue }

            let rect = CGRect(
                x: center.x - flake.size / 2,
                y: center.y - flake.size / 2,
                width: flake.size,
                height: flake.size
            )

            context.opacity = flake.opacity * fade
            context.draw(sprites[flake.spriteIndex], in: rect)
        }

        context.opacity = 1
    }

    /// Draws the snow bank that the flakes have built.
    private func drawPile(in context: inout GraphicsContext, size: CGSize) {
        guard let tallest = pile.heights.max(), tallest > 0.3 else { return }

        let paths = pile.paths(in: size)
        let shadow = Color(red: 0.55, green: 0.65, blue: 0.85)

        // A soft halo so a white bank still reads against a white screen.
        context.stroke(
            paths.edge,
            with: .color(shadow.opacity(0.15)),
            style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
        )

        // White on top, fading to a cool blue-grey where the snow is deep and in shade.
        context.fill(
            paths.fill,
            with: .linearGradient(
                Gradient(colors: [.white, Color(red: 0.78, green: 0.85, blue: 0.95)]),
                startPoint: CGPoint(x: 0, y: size.height - pile.maxHeight(in: size)),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )

        context.stroke(
            paths.edge,
            with: .color(shadow.opacity(0.55)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
        )
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        SnowfallView()
    }
}
