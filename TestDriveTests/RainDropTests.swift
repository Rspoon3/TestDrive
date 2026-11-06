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

    @Test func farDropsLandHigherThanNearDrops() throws {
        let drops = RainDrop.makeDrops(for: .regular)

        let farOffsets = drops.filter { $0.layer == 0 }.map(\.landingOffset)
        let nearOffsets = drops.filter { $0.layer == RainDrop.layerCount - 1 }.map(\.landingOffset)

        #expect(try #require(farOffsets.min()) >= 45)
        #expect(try #require(nearOffsets.max()) <= 14)
    }

    @Test func dropSplashesRightAfterLandingAndStopsWithinItsLifetime() throws {
        let slant = RainfallConfiguration.regular.slantRadians
        let drop = try #require(RainDrop.makeDrops(for: .regular).first)

        let loopHeight = bounds.height + drop.length * 2
        let landingPhase = drop.groundY(in: bounds) + drop.length
        var landing = TimeInterval((landingPhase - drop.startY * loopHeight) / drop.speed)
        if landing < 0 { landing += TimeInterval(loopHeight / drop.speed) }

        let young = try #require(drop.splash(at: landing + 0.01, in: bounds, slantRadians: slant))

        #expect(abs(young.age - 0.01) < 0.001)
        #expect(young.y == drop.groundY(in: bounds))
        #expect(drop.splash(at: landing + RainDrop.splashLifetime + 0.05, in: bounds, slantRadians: slant) == nil)
        #expect(drop.splash(at: landing - 0.01, in: bounds, slantRadians: slant) == nil)
    }

    @Test func splashHappensWhereTheDropLanded() throws {
        let slant = RainfallConfiguration.downpour.slantRadians
        let drop = try #require(RainDrop.makeDrops(for: .downpour).first)

        for time in stride(from: 0.0, through: 20, by: 0.013) {
            guard let splash = drop.splash(at: time, in: bounds, slantRadians: slant) else { continue }

            let impact = drop.position(at: time - splash.age, in: bounds, slantRadians: slant)

            #expect(abs(splash.x - impact.x) < 0.001)
            #expect(splash.age >= 0 && splash.age < RainDrop.splashLifetime)
        }
    }

    @Test func eachDropSplashesOncePerFall() throws {
        let slant = RainfallConfiguration.regular.slantRadians
        let drop = try #require(RainDrop.makeDrops(for: .regular).first)
        let period = TimeInterval((bounds.height + drop.length * 2) / drop.speed)

        // Sample finely over ten falls and count how many separate splashes start.
        var splashes = 0
        var wasSplashing = false
        for time in stride(from: 0.0, through: period * 10, by: 0.005) {
            let isSplashing = drop.splash(at: time, in: bounds, slantRadians: slant) != nil
            if isSplashing && !wasSplashing { splashes += 1 }
            wasSplashing = isSplashing
        }

        #expect(abs(splashes - 10) <= 1)
    }

    @Test func heavierRainSplashesMoreDrops() {
        #expect(RainfallConfiguration.sprinkle.splashFraction < RainfallConfiguration.regular.splashFraction)
        #expect(RainfallConfiguration.regular.splashFraction < RainfallConfiguration.downpour.splashFraction)
    }

    @Test func everyDepthLayerIsPopulated() {
        let layers = Set(RainDrop.makeDrops(for: .regular).map(\.layer))

        #expect(layers == Set(0..<RainDrop.layerCount))
    }
}
