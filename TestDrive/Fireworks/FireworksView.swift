//
//  FireworksView.swift
//  TestDrive
//

import SwiftUI

/// A fireworks show drawn with a SwiftUI `Canvas`, over a darkened sky.
///
/// Every shell is a pure function of time (see ``FireworkShell``), so the show has no per-particle state and runs
/// forever. Sparks are drawn as short streaks with additive blending, so overlapping sparks glow brighter, which is
/// what makes them read as light instead of paint. Each shell's sparks are batched into a handful of paths by color
/// and brightness, so the cost is a few strokes per shell however many sparks there are.
struct FireworksView: View {
    private let configuration: FireworksConfiguration

    @State private var startDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates a fireworks show.
    /// - Parameter configuration: How big the show is.
    init(configuration: FireworksConfiguration = .show) {
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            ZStack {
                // Fireworks need a dark sky, so it fades in over the first second.
                Color.black.opacity(reduceMotion ? 0 : 0.6 * min(1, elapsed))

                Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                    drawShow(in: &context, size: size, elapsed: elapsed)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Private Helpers

    private func drawShow(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        // Bursts of flashing light are exactly what Reduce Motion is meant to remove.
        guard !reduceMotion else { return }

        // Overlapping light adds up instead of covering what is behind it.
        context.blendMode = .plusLighter

        for shell in FireworkShell.shells(at: elapsed, configuration: configuration) {
            if let rocket = shell.rocket(at: elapsed, in: size) {
                drawRocket(rocket, hue: shell.hue, in: &context)
            }

            if let age = shell.burstAge(at: elapsed) {
                drawBurst(of: shell, age: age, in: &context, size: size)
            }
        }
    }

    private func drawRocket(_ rocket: FireworkShell.Rocket, hue: Double, in context: inout GraphicsContext) {
        guard let first = rocket.trail.first else { return }

        var trail = Path()
        trail.move(to: first)
        for point in rocket.trail.dropFirst() {
            trail.addLine(to: point)
        }

        // Spiralling rockets burn in the color of the burst to come, which hints at what is about to happen.
        let color = rocket.isSpiral
            ? Color(hue: hue, saturation: 0.5, brightness: 1)
            : Color(red: 1, green: 0.92, blue: 0.75)

        context.stroke(
            trail,
            with: .color(color.opacity(0.35)),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            trail,
            with: .color(color.opacity(0.9)),
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawBurst(of shell: FireworkShell, age: TimeInterval, in context: inout GraphicsContext, size: CGSize) {
        let kind = shell.kind
        let center = shell.apexPoint(in: size)

        // A quick flash of light at the moment of the burst.
        let flashDuration = 0.18
        if age < flashDuration {
            let fade = 1 - age / flashDuration
            let radius = 60 + 180 * (age / flashDuration)
            let tint = Color(hue: shell.hue, saturation: 0.4, brightness: 1)

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                with: .radialGradient(
                    Gradient(colors: [.white.opacity(0.55 * fade), tint.opacity(0.25 * fade), .clear]),
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
        }

        // Three brightness levels for each of the two colors.
        let brightness: [Double] = [0.9, 0.55, 0.25]
        var buckets = [Path](repeating: Path(), count: 6)

        for index in 0..<kind.sparkCount {
            guard let spark = shell.spark(index: index, age: age, in: size) else { continue }

            let level = spark.alpha > 0.66 ? 0 : (spark.alpha > 0.33 ? 1 : 2)
            let bucket = spark.group * 3 + level

            buckets[bucket].move(to: spark.from)
            buckets[bucket].addLine(to: spark.to)
        }

        for (bucket, path) in buckets.enumerated() where !path.isEmpty {
            let group = bucket / 3
            let level = bucket % 3
            let color = Color(
                hue: group == 0 ? shell.hue : shell.accentHue,
                saturation: kind.saturation,
                brightness: 1
            )

            // The brightest sparks get a wide, faint stroke underneath as a glow.
            if level == 0 {
                context.stroke(
                    path,
                    with: .color(color.opacity(0.2)),
                    style: StrokeStyle(lineWidth: kind.lineWidth * 3, lineCap: .round)
                )
            }

            context.stroke(
                path,
                with: .color(color.opacity(brightness[level])),
                style: StrokeStyle(lineWidth: kind.lineWidth, lineCap: .round)
            )
        }
    }
}

#Preview {
    ZStack {
        Color(white: 0.2).ignoresSafeArea()
        FireworksView(configuration: .finale)
    }
}
