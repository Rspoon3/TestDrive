//
//  WeatherVFXTests.swift
//  TestDriveTests
//

import Foundation
import Testing
@testable import TestDrive

struct WeatherVFXConditionTests {
    private func count(_ name: String, in condition: WeatherVFXCondition, intensity: Float = 1) -> Float {
        condition.count(for: name, intensity: intensity)
    }

    @Test func snowTurnsOnlySnowAndCloudsOn() {
        #expect(count("snowFGParticleCount", in: .snow) == 700)
        #expect(count("snowBGParticleCount", in: .snow) == 1000)
        #expect(count("rainFGParticleCount", in: .snow) == 0)
        #expect(count("hailParticleCount", in: .snow) == 0)
        #expect(count("cloudFGParticleCount", in: .snow) == 10)
        #expect(count("starParticleCount", in: .snow) == 0)
    }

    @Test func clearShowsStarsAndNoClouds() {
        #expect(count("starParticleCount", in: .clear) == 1000)
        #expect(count("cloudFGParticleCount", in: .clear) == 0)

        for name in WeatherVFXCondition.precipitationParameters {
            #expect(count(name, in: .clear) == 0)
        }
    }

    @Test func sunAppearsOnlyInSunny() {
        for name in WeatherVFXCondition.sunParameters {
            #expect(count(name, in: .sunny) > 0)

            for condition in WeatherVFXCondition.allCases where condition != .sunny {
                #expect(count(name, in: condition) == 0)
            }
        }
    }

    @Test(arguments: WeatherVFXCondition.allCases)
    func ambientParticlesAreAlwaysOff(condition: WeatherVFXCondition) {
        for name in WeatherVFXCondition.ambientParameters {
            #expect(count(name, in: condition) == 0)
        }
    }

    @Test func stormIsRainWithLightning() {
        #expect(count("rainFGParticleCount", in: .storm) == 1000)
        #expect(WeatherVFXCondition.storm.hasLightning)
        #expect(!WeatherVFXCondition.rain.hasLightning)
    }

    @Test func intensityScalesPrecipitationButNotClouds() {
        #expect(count("snowFGParticleCount", in: .snow, intensity: 2) == 1400)
        #expect(count("snowFGParticleCount", in: .snow, intensity: 0.5) == 350)
        #expect(count("cloudFGParticleCount", in: .snow, intensity: 2) == 10)
    }

    @Test(arguments: WeatherVFXCondition.allCases)
    func everyConditionActivatesAtMostOnePrecipitationKind(condition: WeatherVFXCondition) {
        let kinds = ["rain", "sleet", "hail", "snow"].filter { kind in
            WeatherVFXCondition.precipitationParameters
                .filter { $0.hasPrefix(kind) }
                .contains { count($0, in: condition) > 0 }
        }

        #expect(kinds.count <= 1)
    }
}

/// Runtime checks run only where the private engine and its matching Weather resources are available.
@MainActor
struct VFXRuntimeTests {
    @Test(.enabled(if: VFXRuntime.isAvailable, "Needs Apple's private VFX engine"))
    func weatherSnowSceneLoadsWithItsDefaults() throws {
        let scene = try #require(VFXSceneHandle(sceneNamed: WeatherVFXViewModel.sceneName))

        #expect((scene.effect.value(forKey: "scene") as? NSObject) === scene.scene)
        #expect(scene.float(named: "snowFGParticleCount") == 700)
        #expect(scene.float(named: "snowBGParticleCount") == 1000)
    }

    @Test(.enabled(if: VFXRuntime.isAvailable, "Needs Apple's private VFX engine"))
    func resourcesMatchTheRunningPlatform() throws {
        let url = try #require(VFXRuntime.sceneURL(named: WeatherVFXViewModel.sceneName))
        let library = try #require(VFXRuntime.shaderLibraryURL)
        #if targetEnvironment(simulator)
        let root = try #require(ProcessInfo.processInfo.environment["SIMULATOR_ROOT"])
        #elseif targetEnvironment(macCatalyst)
        let root = "/System/iOSSupport"
        #else
        let root = ProcessInfo.processInfo.isiOSAppOnMac ? "/System/iOSSupport" : ""
        #endif
        let framework = URL(fileURLWithPath: root + "/System/Library/PrivateFrameworks/WeatherUI.framework")
            .resolvingSymlinksInPath()
        for resource in [url, library] {
            #expect(resource.resolvingSymlinksInPath().path.hasPrefix(framework.path + "/"))
        }
    }

    @Test(.enabled(if: VFXRuntime.isAvailable, "Needs Apple's private VFX engine"))
    func writtenParametersReadBack() throws {
        let scene = try #require(VFXSceneHandle(sceneNamed: WeatherVFXViewModel.sceneName))

        scene.setFloat(42, named: "snowFGParticleCount")

        #expect(scene.float(named: "snowFGParticleCount") == 42)
    }

    @Test(.enabled(if: VFXRuntime.isAvailable, "Needs Apple's private VFX engine"))
    func viewModelAppliesTheConditionToTheScene() throws {
        let viewModel = WeatherVFXViewModel()
        viewModel.loadSceneIfNeeded()
        let scene = try #require(viewModel.scene)

        viewModel.setCondition(.rain)
        #expect(scene.float(named: "rainFGParticleCount") == 1000)
        #expect(scene.float(named: "snowFGParticleCount") == 0)

        viewModel.setIntensity(0.5)
        #expect(scene.float(named: "rainFGParticleCount") == 500)

        viewModel.setCondition(.snow)
        #expect(scene.float(named: "rainFGParticleCount") == 0)
        #expect(scene.float(named: "snowFGParticleCount") == 350)
    }

    @Test func initializationDoesNotLoadTheGPUScene() {
        let viewModel = WeatherVFXViewModel()
        #expect(viewModel.scene == nil)
        #expect(!viewModel.hasAttemptedLoading)
    }

    @Test(.enabled(if: VFXRuntime.isAvailable, "Needs Apple's private VFX engine"))
    func repeatedAppearanceKeepsTheSameScene() throws {
        let viewModel = WeatherVFXViewModel()
        viewModel.loadSceneIfNeeded()
        let original = try #require(viewModel.scene)
        viewModel.loadSceneIfNeeded()
        #expect(viewModel.scene === original)
    }

    @Test func unavailableRuntimeGivesNoScene() {
        guard !VFXRuntime.isAvailable else { return }

        let viewModel = WeatherVFXViewModel()
        viewModel.loadSceneIfNeeded()
        #expect(viewModel.hasAttemptedLoading)
        #expect(viewModel.scene == nil)
        #expect(!viewModel.isAvailable)
    }
}
