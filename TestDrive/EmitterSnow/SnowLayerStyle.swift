//
//  SnowLayerStyle.swift
//  TestDrive
//

import CoreGraphics

/// One depth band of the emitter snowfall.
///
/// The bands slice the same depth range the Canvas snow uses, and size, speed, opacity and wind response come from the
/// same formulas as `SnowFlake.makeFlakes(for:)`, so both implementations look alike. Depth is squared (`biasedDepth`)
/// exactly as there, which is why far bands are tightly packed and the nearest band is the largest and fastest.
///
/// Focus runs the opposite way to the Canvas snow, which makes its near flakes the softest: here far bands use the
/// softest ``SnowSprite`` and near bands use the sharpest, which still has a soft edge.
struct SnowLayerStyle: Equatable {
    /// Diameter of a flake at the middle of the band, in points.
    let size: CGFloat

    /// How far a flake's diameter varies either side of ``size``, in points.
    let sizeRange: CGFloat

    /// Fall speed at the middle of the band, in points per second, before any speed multiplier.
    let speed: CGFloat

    /// Opacity of the flakes in this band, from `0...1`.
    let opacity: Float

    /// The sprite the band's flakes are drawn with.
    let sprite: SnowSprite

    /// How strongly wind pushes flakes in this band. Closer flakes move more.
    let windFactor: CGFloat

    // MARK: - Public Helpers

    /// The number of depth bands.
    static let bandCount = 5

    /// All depth bands, ordered far to near.
    static let all: [SnowLayerStyle] = (0..<bandCount).map { index in
        let nearDepth = CGFloat(index) / CGFloat(bandCount)
        let farDepth = CGFloat(index + 1) / CGFloat(bandCount)

        // The same squaring the Canvas snow uses to bias toward distant flakes.
        let nearBiased = nearDepth * nearDepth
        let farBiased = farDepth * farDepth
        let middle = (nearBiased + farBiased) / 2

        return SnowLayerStyle(
            size: 2 + middle * 12,
            sizeRange: (farBiased - nearBiased) * 12 / 2,
            speed: 22 + middle * 90,
            opacity: Float(0.35 + middle * 0.5 + 0.075),
            sprite: sprite(forDepth: (nearDepth + farDepth) / 2),
            windFactor: 0.3 + middle * 0.7
        )
    }

    // MARK: - Private Helpers

    /// Picks the sprite for a depth, softest for the far bands and sharpest for the near ones.
    /// - Parameter depth: Depth from `0` (far) to `1` (near).
    private static func sprite(forDepth depth: CGFloat) -> SnowSprite {
        switch depth {
        case ..<0.4: .nearBokeh
        case ..<0.7: .mid
        default: .far
        }
    }
}
