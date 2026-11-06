//
//  SnowPileTests.swift
//  TestDriveTests
//

import CoreGraphics
import Testing
@testable import TestDrive

struct SnowPileTests {
    private let size = CGSize(width: 400, height: 800)

    /// Runs a snowfall at 60 fps for the given number of seconds.
    private func simulate(_ configuration: SnowfallConfiguration, seconds: Double, into pile: SnowPile = SnowPile()) -> SnowPile {
        let flakes = SnowFlake.makeFlakes(for: configuration)

        for frame in 0...Int(seconds * 60) {
            pile.update(to: Double(frame) / 60, size: size, flakes: flakes, configuration: configuration)
        }

        return pile
    }

    @Test func startsEmpty() {
        #expect(SnowPile().heights.allSatisfy { $0 == 0 })
    }

    @Test func landingFlakesBuildAPile() {
        let pile = simulate(.medium, seconds: 60)

        #expect(pile.heights.reduce(0, +) > 0)
        #expect(pile.heights.max() ?? 0 > 1)
    }

    @Test func heavierSnowBuildsAFasterPile() {
        let gentle = simulate(.gentle, seconds: 20).heights.reduce(0, +)
        let blizzard = simulate(.blizzard, seconds: 20).heights.reduce(0, +)

        #expect(blizzard > gentle)
    }

    @Test func pileNeverExceedsItsMaximumHeight() {
        let pile = simulate(.blizzard, seconds: 120)

        #expect((pile.heights.max() ?? 0) <= pile.maxHeight(in: size) + 0.001)
    }

    @Test func steepSlopesSlumpIntoMounds() {
        let pile = simulate(.blizzard, seconds: 60)
        let steepest = zip(pile.heights, pile.heights.dropFirst()).map { abs($0 - $1) }.max() ?? 0

        // The angle of repose limits the slope between columns, with a little slack for a frame's worth of snow.
        #expect(steepest < 10)
    }

    @Test func isDeterministic() {
        #expect(simulate(.medium, seconds: 30).heights == simulate(.medium, seconds: 30).heights)
    }

    @Test func longGapsDoNotDumpSnow() {
        let pile = SnowPile()
        let flakes = SnowFlake.makeFlakes(for: .blizzard)

        pile.update(to: 0, size: size, flakes: flakes, configuration: .blizzard)
        pile.update(to: 500, size: size, flakes: flakes, configuration: .blizzard)

        #expect(pile.heights.allSatisfy { $0 == 0 })
    }

    @Test func surfaceFollowsThePile() {
        let pile = simulate(.blizzard, seconds: 30)
        let tallestColumn = pile.heights.indices.max { pile.heights[$0] < pile.heights[$1] } ?? 0
        let columnX = (CGFloat(tallestColumn) + 0.5) * size.width / CGFloat(SnowPile.columnCount)

        #expect(pile.surfaceY(atX: columnX, in: size) == size.height - pile.heights[tallestColumn])
    }

    @Test func heavierSnowIsScaledSoLightSnowStillShowsAPile() {
        #expect(SnowfallConfiguration.gentle.depositScale > SnowfallConfiguration.medium.depositScale)
        #expect(SnowfallConfiguration.medium.depositScale > SnowfallConfiguration.blizzard.depositScale)
    }
}
