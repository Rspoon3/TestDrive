//
//  SnowIntensityTests.swift
//  TestDriveTests
//

import CoreGraphics
import Testing
@testable import TestDrive

struct SnowIntensityTests {
    @Test func intensitiesEscalate() {
        #expect(SnowfallConfiguration.gentle.flakeCount < SnowfallConfiguration.medium.flakeCount)
        #expect(SnowfallConfiguration.medium.flakeCount < SnowfallConfiguration.blizzard.flakeCount)
        #expect(SnowfallConfiguration.gentle.speedMultiplier < SnowfallConfiguration.blizzard.speedMultiplier)
    }

    @Test func onlyBlizzardHasSteadyWindAndHaze() {
        #expect(SnowfallConfiguration.blizzard.windDrift > 0)
        #expect(SnowfallConfiguration.blizzard.hazeOpacity > 0)
        #expect(SnowfallConfiguration.medium.windDrift == 0)
        #expect(SnowfallConfiguration.medium.hazeOpacity == 0)
    }

    @Test func driftPushesFlakesSidewaysOverTime() throws {
        let bounds = CGSize(width: 400, height: 800)
        let flake = try #require(SnowFlake.makeFlakes(for: .medium).last)

        let calm = flake.position(at: 0.5, in: bounds, windStrength: 0, windDrift: 0)
        let blown = flake.position(at: 0.5, in: bounds, windStrength: 0, windDrift: 300)

        #expect(calm.x != blown.x)
        #expect(calm.y == blown.y)
    }

    @Test func blizzardFlakesStayWithinMarginAcrossTime() {
        let bounds = CGSize(width: 400, height: 800)
        let configuration = SnowfallConfiguration.blizzard

        for time in stride(from: 0.0, through: 300, by: 5.3) {
            for flake in SnowFlake.makeFlakes(for: configuration) {
                let point = flake.position(
                    at: time,
                    in: bounds,
                    windStrength: configuration.windStrength,
                    windDrift: configuration.windDrift
                )
                let margin = flake.size * 2 + flake.swayAmplitude + configuration.windStrength

                #expect(point.x >= -margin && point.x <= bounds.width + margin)
            }
        }
    }
}
