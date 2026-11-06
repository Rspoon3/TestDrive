//
//  DragMotion.swift
//  TestDrive
//

import CoreGraphics
import Foundation

/// Closed-form motion for a particle that is pulled by gravity and slowed by air.
///
/// Confetti and firework sparks both need to start fast and then slow to a drift. Stepping that frame by frame would
/// need state per particle. Solving it exactly means the position at any time is one formula, so particles stay
/// stateless like the snow and rain.
enum DragMotion {
    /// How far a particle has moved from its start.
    /// - Parameters:
    ///   - velocity: Launch velocity in points per second.
    ///   - gravity: Downward acceleration in points per second squared. Pass `0` for none.
    ///   - drag: Air resistance as a rate per second. Higher values slow the particle faster, and with gravity it sets
    ///     the terminal fall speed (`gravity / drag`).
    ///   - time: Seconds since launch.
    /// - Returns: The displacement from the launch point.
    static func displacement(velocity: CGVector, gravity: CGFloat, drag: CGFloat, time: CGFloat) -> CGVector {
        guard drag > 0.0001 else {
            return CGVector(dx: velocity.dx * time, dy: velocity.dy * time + 0.5 * gravity * time * time)
        }

        // The distance a particle would cover at its starting speed if it slowed exponentially.
        let travel = (1 - exp(-drag * time)) / drag
        let terminalSpeed = gravity / drag

        return CGVector(
            dx: velocity.dx * travel,
            dy: (velocity.dy - terminalSpeed) * travel + terminalSpeed * time
        )
    }
}
