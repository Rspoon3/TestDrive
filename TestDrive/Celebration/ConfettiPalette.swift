//
//  ConfettiPalette.swift
//  TestDrive
//

import SwiftUI
import UIKit

/// The colors shared by both confetti engines, so they look like the same party.
enum ConfettiPalette {
    private static let rgb: [(red: Double, green: Double, blue: Double)] = [
        (149, 58, 255), (255, 195, 41), (255, 101, 26),
        (123, 92, 255), (76, 126, 255), (71, 192, 255),
        (255, 47, 39), (255, 91, 134), (233, 122, 208)
    ]

    /// How much darker a piece looks when its back is facing the viewer.
    private static let backShade = 0.7

    /// The bright side of each color.
    static let colors: [Color] = rgb.map { Color(red: $0.red / 255, green: $0.green / 255, blue: $0.blue / 255) }

    /// The darker, shaded back of each color, used when a piece flips over.
    static let shadedColors: [Color] = rgb.map {
        Color(red: $0.red / 255 * backShade, green: $0.green / 255 * backShade, blue: $0.blue / 255 * backShade)
    }

    /// The bright colors as `UIColor`, for Core Animation.
    static let uiColors: [UIColor] = rgb.map {
        UIColor(red: $0.red / 255, green: $0.green / 255, blue: $0.blue / 255, alpha: 1)
    }
}
