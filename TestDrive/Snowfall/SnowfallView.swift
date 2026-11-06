//
//  SnowfallView.swift
//  TestDrive
//

import SwiftUI

/// A realistic, GPU-friendly snowfall that can be overlaid on any screen.
///
/// How it stays fast:
/// - One `Canvas` draws every flake, so there is no per-flake view or layout.
/// - Flakes are stamped from three sprites that SwiftUI rasterizes once. Softness comes from a radial gradient baked
///   into the sprite, so there are no per-frame blur filters.
/// - Flake positions are a pure function of time (see ``SnowFlake/position(at:in:windStrength:)``), so nothing is
///   mutated or allocated per frame.
/// - `TimelineView(.animation)` lets the system pick the refresh rate, including ProMotion, and stops when the
///   app is not visible.
///
/// How it looks real: three depth layers (large soft near flakes, crisp tiny far flakes) with parallax speed, a shared
/// wind that near flakes feel more, and per-flake flutter.
struct SnowfallView: View {
    private let configuration: SnowfallConfiguration
    private let flakes: [SnowFlake]

    @State private var startDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates a snowfall.
    /// - Parameter configuration: Controls flake count, speed, and wind.
    init(configuration: SnowfallConfiguration = .default) {
        self.configuration = configuration
        flakes = SnowFlake.makeFlakes(for: configuration)
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                drawFlakes(in: &context, size: size, elapsed: elapsed)
            } symbols: {
                ForEach(SnowSprite.allCases) { sprite in
                    sprite.view
                        .tag(sprite.rawValue)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Private Helpers

    /// Stamps every flake onto the canvas.
    private func drawFlakes(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        // Resolve each sprite once per frame, outside the flake loop.
        let sprites = SnowSprite.allCases.compactMap { context.resolveSymbol(id: $0.rawValue) }
        guard sprites.count == SnowSprite.allCases.count else { return }

        for flake in flakes {
            let center = flake.position(at: elapsed, in: size, windStrength: configuration.windStrength)
            let rect = CGRect(
                x: center.x - flake.size / 2,
                y: center.y - flake.size / 2,
                width: flake.size,
                height: flake.size
            )

            context.opacity = flake.opacity
            context.draw(sprites[flake.spriteIndex], in: rect)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        SnowfallView()
    }
}
