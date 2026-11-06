//
//  RainDropTests.swift
//  TestDriveTests
//

import CoreGraphics
import Testing
@testable import TestDrive

struct RainDropTests {
    private let bounds = CGSize(width: 400, height: 800)

    @Test(arguments: [RainIntensity.sprinkle, .regular, .downpour])
    func generatesRequestedCountDeterministically(intensity: RainIntensity) {
        let configuration = intensity.configuration

        #expect(RainDrop.makeDrops(for: configuration).count == configuration.dropCount)
        #expect(RainDrop.makeDrops(for: configuration) == RainDrop.makeDrops(for: configuration))
    }

    @Test func heavierRainHasMoreDropsAndMoreSlant() {
        #expect(RainfallConfiguration.sprinkle.dropCount < RainfallConfiguration.regular.dropCount)
        #expect(RainfallConfiguration.regular.dropCount < RainfallConfiguration.downpour.dropCount)
        #expect(RainfallConfiguration.sprinkle.slantDegrees < RainfallConfiguration.downpour.slantDegrees)
    }

    @Test func dropsStayWithinMarginAcrossTime() {
        let slant = RainfallConfiguration.downpour.slantRadians
        let drops = RainDrop.makeDrops(for: .downpour)

        for time in stride(from: 0.0, through: 300, by: 3.7) {
            for drop in drops {
                let point = drop.position(at: time, in: bounds, slantRadians: slant)

                #expect(point.y >= -drop.length && point.y <= bounds.height + drop.length)
                #expect(point.x >= -drop.length && point.x <= bounds.width + drop.length)
            }
        }
    }

    @Test func everyDepthLayerIsPopulated() {
        let layers = Set(RainDrop.makeDrops(for: .regular).map(\.layer))

        #expect(layers == Set(0..<RainDrop.layerCount))
    }
}
