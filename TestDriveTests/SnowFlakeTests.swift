//
//  SnowFlakeTests.swift
//  TestDriveTests
//

import CoreGraphics
import Testing
@testable import TestDrive

struct SnowFlakeTests {
    private let bounds = CGSize(width: 400, height: 800)

    @Test func generatesRequestedCountDeterministically() {
        let configuration = SnowfallConfiguration(flakeCount: 50)

        #expect(SnowFlake.makeFlakes(for: configuration).count == 50)
        #expect(SnowFlake.makeFlakes(for: configuration) == SnowFlake.makeFlakes(for: configuration))
    }

    @Test func flakesStayWithinMarginAcrossTime() {
        let flakes = SnowFlake.makeFlakes(for: .default)
        let windStrength = SnowfallConfiguration.default.windStrength

        for time in stride(from: 0.0, through: 600, by: 7.3) {
            for flake in flakes {
                let point = flake.position(at: time, in: bounds, windStrength: windStrength)
                let margin = flake.size * 2 + flake.swayAmplitude + windStrength

                #expect(point.y >= -margin && point.y <= bounds.height + margin)
                #expect(point.x >= -margin && point.x <= bounds.width + margin)
            }
        }
    }

    @Test func flakesFallDownward() throws {
        let flake = try #require(SnowFlake.makeFlakes(for: .default).first)
        let early = flake.position(at: 1, in: bounds, windStrength: 0)
        let later = flake.position(at: 1.1, in: bounds, windStrength: 0)

        // Unless it wrapped around the bottom in that 0.1s window, it must have moved down.
        #expect(later.y > early.y || later.y < -flake.size)
    }
}
