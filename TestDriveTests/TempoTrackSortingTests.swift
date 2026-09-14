//
//  TempoTrackSortingTests.swift
//  TestDriveTests
//

import MusicKit
import Testing
@testable import TestDrive

@MainActor
struct TempoTrackSortingTests {

    @Test("Measured songs are ordered fastest first")
    func ordersMeasuredSongsByDescendingTempo() {
        let sorted = TempoTrack.sortedByDescendingTempo([
            .stub(id: "slow", tempoState: .measured(bpm: 92, source: .preview)),
            .stub(id: "fast", tempoState: .measured(bpm: 174, source: .preview)),
            .stub(id: "medium", tempoState: .measured(bpm: 128, source: .fullTrack))
        ])

        #expect(sorted.map(\.id.rawValue) == ["fast", "medium", "slow"])
    }

    @Test("Unmeasured songs sink below measured ones")
    func placesUnmeasuredSongsLast() {
        let sorted = TempoTrack.sortedByDescendingTempo([
            .stub(id: "protected", tempoState: .unavailable(.protectedContent)),
            .stub(id: "pending", tempoState: .pending),
            .stub(id: "measured", tempoState: .measured(bpm: 100, source: .preview)),
            .stub(id: "analyzing", tempoState: .analyzing)
        ])

        #expect(sorted.map(\.id.rawValue) == ["measured", "pending", "analyzing", "protected"])
    }

    @Test("Ties keep their incoming order so rows don't shuffle mid-analysis")
    func keepsIncomingOrderForTies() {
        let sorted = TempoTrack.sortedByDescendingTempo([
            .stub(id: "first", tempoState: .measured(bpm: 120, source: .preview)),
            .stub(id: "second", tempoState: .measured(bpm: 120, source: .preview)),
            .stub(id: "third", tempoState: .measured(bpm: 120, source: .fullTrack))
        ])

        #expect(sorted.map(\.id.rawValue) == ["first", "second", "third"])
    }

    @Test("Sorting an empty playlist produces nothing")
    func handlesEmptyInput() {
        #expect(TempoTrack.sortedByDescendingTempo([]).isEmpty)
    }

    @Test("Only measured states expose a BPM")
    func exposesBPMOnlyWhenMeasured() {
        #expect(TempoState.measured(bpm: 145, source: .preview).bpm == 145)
        #expect(TempoState.pending.bpm == nil)
        #expect(TempoState.analyzing.bpm == nil)
        #expect(TempoState.unavailable(.noTempoDetected).bpm == nil)
    }

    @Test("Pending and analyzing songs report as in progress")
    func reportsInProgressStates() {
        #expect(TempoState.pending.isInProgress)
        #expect(TempoState.analyzing.isInProgress)
        #expect(!TempoState.measured(bpm: 120, source: .preview).isInProgress)
        #expect(!TempoState.unavailable(.protectedContent).isInProgress)
    }
}

private extension TempoTrack {
    /// Builds a minimal track for sorting assertions.
    static func stub(id: MusicItemID, tempoState: TempoState) -> TempoTrack {
        TempoTrack(
            id: id,
            title: id.rawValue,
            artistName: "Test Artist",
            tempoState: tempoState
        )
    }
}
