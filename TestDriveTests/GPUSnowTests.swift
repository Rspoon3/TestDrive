//
//  GPUSnowTests.swift
//  TestDriveTests
//

import CoreGraphics
import QuartzCore
import Testing
@testable import TestDrive

struct GPUSnowTests {

    // MARK: - SnowShaderParameters

    @Test func shaderParametersHaveAHeaderAndSevenFloatsPerLayer() {
        let parameters = SnowShaderParameters.make(for: .medium)

        let expected = SnowShaderParameters.headerCount
            + SnowShaderParameters.floatsPerLayer * SnowLayerStyle.bandCount
        #expect(parameters.count == expected)
    }

    @Test func shaderParametersCarryTheWindAndTheSpeedMultiplier() {
        let configuration = SnowfallConfiguration.blizzard
        let parameters = SnowShaderParameters.make(for: configuration)

        #expect(parameters[0] == Float(configuration.windStrength))
        #expect(parameters[1] == Float(configuration.windDrift))

        // Layer 0, field 2 is the speed.
        let firstSpeed = parameters[SnowShaderParameters.headerCount + 2]
        let expected = Float(SnowLayerStyle.all[0].speed * configuration.speedMultiplier)
        #expect(firstSpeed == expected)
    }

    @Test func shaderParametersSplitTheFlakeCountAcrossLayers() {
        let parameters = SnowShaderParameters.make(for: .medium)
        let flakeCountField = SnowShaderParameters.headerCount + 6

        #expect(parameters[flakeCountField] == Float(SnowfallConfiguration.medium.flakeCount) / 5)
    }

    // MARK: - Instanced renderer layout

    @Test func instanceAndUniformLayoutsMatchTheShaders() {
        // `SnowInstance` is ten packed floats and `SnowUniforms` is a float2 plus three floats, as in the .metal file.
        #expect(MemoryLayout<SnowInstance>.stride == 40)
        #expect(MemoryLayout<SnowUniforms>.stride == 24)
    }

    @Test func instancesMirrorTheCanvasFlakes() {
        let configuration = SnowfallConfiguration.medium
        let flakes = SnowFlake.makeFlakes(for: configuration)
        let instances = SnowInstance.makeInstances(for: configuration)

        #expect(instances.count == flakes.count)
        #expect(instances.first?.size == Float(flakes[0].size))
    }

    @Test func instancesFlipTheCanvasSpriteSoFarFlakesAreSoft() {
        let configuration = SnowfallConfiguration.medium
        let flakes = SnowFlake.makeFlakes(for: configuration)
        let instances = SnowInstance.makeInstances(for: configuration)

        for (flake, instance) in zip(flakes, instances) {
            // The Canvas draws its crisp sprite (2) on far flakes. The GPU views want the softest (0) there.
            #expect(instance.spriteKind == Float(2 - flake.spriteIndex))
        }
    }

    // MARK: - CAML scenes

    @Test(arguments: SnowIntensity.allCases)
    func bundledCAMLScenesLoadIntoFiveEmitters(intensity: SnowIntensity) throws {
        let name = camlSceneName(for: intensity)
        let root = try #require(CAMLPackage.rootLayer(named: name), "\(name).caml should load through CAPackage")
        let emitters = (root.sublayers ?? []).compactMap { $0 as? CAEmitterLayer }

        #expect(emitters.count == SnowLayerStyle.bandCount)
    }

    @Test func mediumCAMLSceneMatchesTheDepthBands() throws {
        let root = try #require(CAMLPackage.rootLayer(named: "snow-medium"))
        let emitters = (root.sublayers ?? []).compactMap { $0 as? CAEmitterLayer }

        for (emitter, style) in zip(emitters, SnowLayerStyle.all) {
            let cell = try #require(emitter.emitterCells?.first)

            // With a drag of 1, gravity equals the fall speed.
            #expect(abs(Double(cell.yAcceleration) - Double(style.speed)) < 0.01)
            #expect(abs(Double(cell.scale) - Double(style.size / SnowFlakeImage.diameter)) < 0.001)
        }
    }

    // MARK: - Private Helpers

    private func camlSceneName(for intensity: SnowIntensity) -> String {
        switch intensity {
        case .gentle: "snow-gentle"
        case .medium: "snow-medium"
        case .blizzard: "snow-blizzard"
        }
    }
}
