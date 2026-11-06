//
//  ConfettiEngine.swift
//  TestDrive
//

/// Which implementation draws the confetti. Both support the same ``ConfettiStyle`` options.
enum ConfettiEngine: String, CaseIterable, Identifiable {
    /// `CAEmitterLayer` particle emitters, the approach the Fetch app uses.
    case coreAnimation = "Core Animation"

    /// A SwiftUI `Canvas` where every piece's position is a pure function of time.
    case canvas = "SwiftUI Canvas"

    var id: String { rawValue }
}
