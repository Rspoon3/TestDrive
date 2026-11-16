//
//  SnowEngine.swift
//  TestDrive
//

/// Which implementation draws the snow. Both use the same ``SnowIntensity`` settings.
enum SnowEngine: String, CaseIterable, Identifiable {
    /// A SwiftUI `Canvas` where every flake's position is a pure function of time. Builds a snow pile.
    case canvas = "SwiftUI Canvas"

    /// `CAEmitterLayer` emitters with private `CAEmitterBehavior` forces from the EmitterBehaviors package.
    case emitterBehaviors = "Emitter Behaviors"

    var id: String { rawValue }
}
