//
//  SnowSprite.swift
//  TestDrive
//

import SwiftUI

/// The three pre-rendered flake looks that a ``SnowfallView`` stamps onto its canvas.
///
/// The index matches ``SnowFlake/spriteIndex``.
enum SnowSprite: Int, CaseIterable, Identifiable {
    /// Large, very soft, out-of-focus flakes close to the camera.
    case nearBokeh = 0

    /// Medium flakes with a soft edge.
    case mid = 1

    /// Tiny, crisp flakes far away.
    case far = 2

    var id: Int { rawValue }

    /// The sprite's view. SwiftUI rasterizes it once and the canvas reuses it for every flake.
    var view: some View {
        Circle()
            .fill(
                RadialGradient(
                    stops: gradientStops,
                    center: .center,
                    startRadius: 0,
                    endRadius: 16
                )
            )
            .frame(width: 32, height: 32)
    }

    // MARK: - Private Helpers

    /// Where opacity falls off. A lower solid core means a softer flake.
    private var gradientStops: [Gradient.Stop] {
        switch self {
        case .nearBokeh:
            [
                .init(color: .white.opacity(0.85), location: 0),
                .init(color: .white.opacity(0.35), location: 0.5),
                .init(color: .white.opacity(0), location: 1)
            ]
        case .mid:
            [
                .init(color: .white, location: 0),
                .init(color: .white.opacity(0.75), location: 0.45),
                .init(color: .white.opacity(0), location: 1)
            ]
        case .far:
            [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.6),
                .init(color: .white.opacity(0), location: 1)
            ]
        }
    }
}
