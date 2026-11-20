//
//  SpriteKitSnowView.swift
//  TestDrive
//

import SpriteKit
import SwiftUI

/// A full-bleed snowfall drawn by SpriteKit's particle emitters in a `SpriteView`.
///
/// It takes the same ``SnowfallConfiguration`` as the other snow views and uses the same depth bands as
/// ``SnowLayerStyle``. See ``SnowScene``. There is no snow pile and no blizzard haze.
struct SpriteKitSnowView: View {
    private let configuration: SnowfallConfiguration

    @State private var scene: SnowScene
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer

    /// Creates the snow.
    /// - Parameter configuration: How much snow falls, how fast, and how windy it is.
    init(configuration: SnowfallConfiguration = .default) {
        self.configuration = configuration
        _scene = State(initialValue: SnowScene(configuration: configuration))
    }

    // MARK: - Body

    var body: some View {
        SpriteView(scene: scene, isPaused: reduceMotion, options: [.allowsTransparency])
            .opacity(reduceMotion ? 0 : 1)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: configuration) { _, newConfiguration in
                scene.configuration = newConfiguration
            }
    }
}

#Preview {
    ZStack {
        Color.black
        SpriteKitSnowView()
    }
    .ignoresSafeArea()
}
