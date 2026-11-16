//
//  SnowFlakeImage.swift
//  TestDrive
//

import SwiftUI

/// Rasterizes the snowflake sprites used by the emitter cells.
///
/// These are the same ``SnowSprite`` views the Canvas snow stamps, so a flake's softness matches between the two
/// implementations. As in iMessage confetti, the blur is baked into the sprite rather than applied as a layer filter.
enum SnowFlakeImage {

    /// The width and height of every flake image, in points. This is the frame ``SnowSprite`` draws in, and cells scale
    /// it to the size they want.
    static let diameter: CGFloat = 32

    /// Renders a sprite to an image.
    /// - Parameters:
    ///   - sprite: Which flake look to draw.
    ///   - scale: The screen scale to draw at. Give the same value to the emitter cell's `contentsScale`, because a
    ///     cell otherwise reads the image's pixel size as points and draws the flake `scale` times too large.
    /// - Returns: The flake image, or `nil` if rendering failed.
    @MainActor
    static func make(sprite: SnowSprite, scale: CGFloat) -> CGImage? {
        let renderer = ImageRenderer(content: sprite.view)
        renderer.scale = scale
        return renderer.cgImage
    }
}
