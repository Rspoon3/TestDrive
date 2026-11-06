//
//  Referral.swift
//  TestDrive
//

import SwiftUI

/// A friend who was invited with the user's code.
struct Referral: Identifiable, Equatable {
    let id = UUID()

    /// Display name, e.g. "Braden D.".
    let name: String

    /// Pre-formatted join date, e.g. "Jun 3, 2026".
    let joinedText: String

    /// Points the invite is worth.
    let points: Int

    /// SF Symbol shown in the avatar.
    let symbolName: String

    /// Pastel background of the avatar.
    let avatarBackground: Color

    /// Tint of the avatar symbol.
    let avatarTint: Color

    /// Whether the friend still needs a nudge to finish signing up.
    let canRemind: Bool
}
