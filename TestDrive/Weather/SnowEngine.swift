//
//  SnowEngine.swift
//  TestDrive
//

/// Which implementation draws the snow. All of them use the same ``SnowIntensity`` settings.
enum SnowEngine: String, CaseIterable, Identifiable {
    /// A SwiftUI `Canvas` where every flake's position is a pure function of time. Builds a snow pile.
    case canvas = "SwiftUI Canvas"

    /// `CAEmitterLayer` emitters with private `CAEmitterBehavior` forces from the EmitterBehaviors package.
    case emitterBehaviors = "Emitter Behaviors"

    /// A bundled Core Animation Markup Language (`.caml`) scene, the format Apple's Weather app used before iOS 15.
    case caml = "CAML Scene"

    /// A procedural Metal fragment shader applied with SwiftUI's `colorEffect`. No particles at all.
    case metalShader = "Metal Shader"

    /// One instanced Metal draw call in an `MTKView`, with positions worked out in the vertex shader.
    case metalInstanced = "Metal Instanced"

    /// SpriteKit's `SKEmitterNode`s in a `SpriteView`.
    case spriteKit = "SpriteKit"

    var id: String { rawValue }
}
