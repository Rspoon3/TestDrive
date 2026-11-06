//
//  ConfettiStyle.swift
//  TestDrive
//

/// How the confetti arrives.
enum ConfettiStyle: String, CaseIterable, Identifiable {
    /// A burst of confetti that is blasted onto the screen and rains down.
    case cannonBlast = "Cannon blast"

    /// Confetti that rains down from above the top of the screen.
    case rain = "Rain"

    var id: String { rawValue }
}
