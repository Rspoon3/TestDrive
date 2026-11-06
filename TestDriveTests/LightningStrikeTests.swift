//
//  LightningStrikeTests.swift
//  TestDriveTests
//

import CoreGraphics
import Testing
@testable import TestDrive

struct LightningStrikeTests {
    private let seed: UInt64 = 2026

    @Test func strikesAreDeterministic() {
        for slot in 0..<50 {
            let time = Double(slot) * LightningStrike.slotLength
            #expect(LightningStrike.strike(at: time, seed: seed) == LightningStrike.strike(at: time, seed: seed))
        }
    }

    @Test func mostSlotsHaveAStrikeButNotAll() {
        let strikes = (0..<200).compactMap { slot in
            LightningStrike.strike(at: Double(slot) * LightningStrike.slotLength, seed: seed)
        }

        #expect(strikes.count > 100)
        #expect(strikes.count < 200)
    }

    @Test func strikeFinishesInsideItsOwnSlot() throws {
        for slot in 0..<200 {
            let slotStart = Double(slot) * LightningStrike.slotLength
            guard let strike = LightningStrike.strike(at: slotStart, seed: seed) else { continue }

            let lastPulseEnd = try #require(strike.pulses.map { $0.offset + $0.duration }.max())

            #expect(strike.startTime >= slotStart)
            #expect(strike.startTime + lastPulseEnd <= slotStart + LightningStrike.slotLength)
        }
    }

    @Test func intensityIsDarkBeforeAndAfterAndBoundedWhileFlashing() throws {
        let strike = try #require((0..<50).compactMap { slot in
            LightningStrike.strike(at: Double(slot) * LightningStrike.slotLength, seed: seed)
        }.first)

        #expect(strike.intensity(at: strike.startTime - 0.5) == 0)
        #expect(strike.intensity(at: strike.startTime + 5) == 0)
        #expect(strike.intensity(at: strike.startTime) > 0.9)

        for step in 0..<200 {
            let value = strike.intensity(at: strike.startTime + Double(step) * 0.01)
            #expect(value >= 0 && value <= 1)
        }
    }

    @Test func boltPathIsNotEmptyAndStaysNearItsStartX() throws {
        let size = CGSize(width: 400, height: 800)
        let strike = try #require((0..<50).compactMap { slot in
            LightningStrike.strike(at: Double(slot) * LightningStrike.slotLength, seed: seed)
        }.first)

        let bounds = strike.boltPaths(in: size).main.boundingRect

        #expect(!bounds.isEmpty)
        #expect(bounds.minY < 0)
        #expect(bounds.maxY > size.height * 0.5)
    }

    @Test func onlyDownpourHasLightning() {
        #expect(RainfallConfiguration.downpour.hasLightning)
        #expect(!RainfallConfiguration.regular.hasLightning)
        #expect(!RainfallConfiguration.sprinkle.hasLightning)
    }
}
