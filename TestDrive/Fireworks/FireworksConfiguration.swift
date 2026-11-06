//
//  FireworksConfiguration.swift
//  TestDrive
//

import Foundation

/// Tunable parameters for a ``FireworksView``.
///
/// Time is split into slots, and each slot may launch shells. That makes the show reproducible and endless without any
/// stored schedule.
struct FireworksConfiguration: Equatable {
    /// Length of one slot, in seconds.
    var slotLength: TimeInterval = 1.4

    /// How many shells each slot may launch.
    var shellsPerSlot = 1

    /// Chance, from `0...1`, that each shell actually launches.
    var launchProbability = 0.95

    /// Seed so the same configuration always puts on the same show.
    var seed: UInt64 = 2026

    /// An occasional single shell.
    static let sparse = FireworksConfiguration(slotLength: 2.4, shellsPerSlot: 1, launchProbability: 0.8)

    /// A steady show.
    static let show = FireworksConfiguration()

    /// Overlapping volleys, like the end of a real show.
    static let finale = FireworksConfiguration(slotLength: 0.8, shellsPerSlot: 2, launchProbability: 1)
}
