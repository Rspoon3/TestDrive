//
//  SnowLayerStyleTests.swift
//  TestDriveTests
//

import CoreGraphics
import Testing
@testable import TestDrive

struct SnowLayerStyleTests {
    @Test func bandsCoverTheCanvasSnowSizeRange() {
        // `SnowFlake` sizes flakes from 2 to 14 points.
        for style in SnowLayerStyle.all {
            #expect(style.size - style.sizeRange >= 2 - 0.001)
            #expect(style.size + style.sizeRange <= 14 + 0.001)
        }
    }

    @Test func bandsStayWithinTheCanvasSnowSpeedRange() {
        // `SnowFlake` speeds run from 22 to 112 points per second before jitter.
        for style in SnowLayerStyle.all {
            #expect(style.speed >= 22)
            #expect(style.speed <= 112)
        }
    }

    @Test func nearBandsAreLargerFasterAndMoreOpaque() {
        let bands = SnowLayerStyle.all

        for (far, near) in zip(bands, bands.dropFirst()) {
            #expect(near.size > far.size)
            #expect(near.speed > far.speed)
            #expect(near.opacity > far.opacity)
            #expect(near.windFactor > far.windFactor)
        }
    }

    @Test func farBandsUseTheSoftestSpriteAndNearBandsTheSharpest() {
        let bands = SnowLayerStyle.all

        #expect(bands.count == SnowLayerStyle.bandCount)
        #expect(bands.first!.sprite == .nearBokeh)
        #expect(bands.last!.sprite == .far)
    }
}
