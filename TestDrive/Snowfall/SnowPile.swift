//
//  SnowPile.swift
//  TestDrive
//

import CoreGraphics
import SwiftUI

/// The snow bank along the bottom of the screen, built by flakes that really land on it.
///
/// The bank is a row of column heights. Every frame, ``update(to:size:flakes:configuration:)`` checks which flakes
/// crossed the surface since the last frame and adds a little snow where each one hit. Because the flakes themselves
/// are pure functions of time, "where was this flake a frame ago" is just another call, so the flakes stay stateless
/// and this height map is the only mutable state.
///
/// Two things make it look like snow and not a bar chart:
/// - Each landing is spread over three neighbouring columns.
/// - Slopes steeper than snow's angle of repose slump sideways, so the bank settles into soft mounds.
///
/// Owned by the view model, not the view, so the pile survives intensity changes.
final class SnowPile {
    /// Number of columns across the screen.
    static let columnCount = 96

    /// Height gained per unit of flake area, before intensity scaling. Tune this to make piles build faster or slower.
    private static let depositPerArea: CGFloat = 0.08

    /// How steep snow can stay, as rise over run (about 35°). Steeper slopes slump.
    private static let angleOfRepose: CGFloat = 0.7

    /// The pile's height in points at each column.
    private(set) var heights = [CGFloat](repeating: 0, count: SnowPile.columnCount)

    private var lastTime: TimeInterval?

    // MARK: - Public Helpers

    /// The height of a full pile at its tallest point.
    /// - Parameter size: The size of the area the pile sits in.
    func maxHeight(in size: CGSize) -> CGFloat {
        min(170, size.height * 0.2)
    }

    /// Where the snow's surface is at a given horizontal position.
    /// - Parameters:
    ///   - x: Horizontal position in points.
    ///   - size: The size of the area the pile sits in.
    /// - Returns: The y coordinate of the surface. A flake below it has landed.
    func surfaceY(atX x: CGFloat, in size: CGSize) -> CGFloat {
        size.height - heights[column(forX: x, width: size.width)]
    }

    /// Adds snow for every flake that crossed the surface since the previous call.
    /// - Parameters:
    ///   - time: Seconds since the snowfall started, the same clock the flakes use.
    ///   - size: The size of the area the snow falls through.
    ///   - flakes: The falling flakes.
    ///   - configuration: The snowfall that produced the flakes.
    func update(to time: TimeInterval, size: CGSize, flakes: [SnowFlake], configuration: SnowfallConfiguration) {
        defer { lastTime = time }

        // Skip the first frame, a clock that went backwards, and long gaps (such as returning from the background),
        // where "crossed since last frame" would be meaningless.
        guard size.width > 0, let last = lastTime, time > last, time - last < 0.25 else { return }

        let cap = maxHeight(in: size)

        for flake in flakes {
            let previous = flake.position(
                at: last,
                in: size,
                windStrength: configuration.windStrength,
                windDrift: configuration.windDrift
            )
            let current = flake.position(
                at: time,
                in: size,
                windStrength: configuration.windStrength,
                windDrift: configuration.windDrift
            )

            // A flake that moved up wrapped around to the top, so it didn't land.
            guard current.y > previous.y else { continue }

            let column = column(forX: current.x, width: size.width)
            let surface = size.height - heights[column]
            guard previous.y < surface, current.y >= surface else { continue }

            // Snow slows down as the pile nears its limit instead of stopping with a hard edge.
            let room = max(0, 1 - heights[column] / cap)
            let amount = flake.size * flake.size * Self.depositPerArea
                * CGFloat(configuration.depositScale) * room * room

            add(amount * 0.25, to: column - 1, cap: cap)
            add(amount * 0.5, to: column, cap: cap)
            add(amount * 0.25, to: column + 1, cap: cap)
        }

        relax(maxDifference: size.width / CGFloat(Self.columnCount) * Self.angleOfRepose)
    }

    /// The outline of the pile.
    /// - Parameter size: The size of the area the pile sits in.
    /// - Returns: A filled shape that reaches just below the bottom edge, and the smooth top edge on its own.
    func paths(in size: CGSize) -> (fill: Path, edge: Path) {
        let step = size.width / CGFloat(Self.columnCount)

        // Column centres, with the first and last height extended to the screen edges.
        var points = [CGPoint(x: 0, y: size.height - heights[0])]
        for (index, height) in heights.enumerated() {
            points.append(CGPoint(x: (CGFloat(index) + 0.5) * step, y: size.height - height))
        }
        points.append(CGPoint(x: size.width, y: size.height - heights[heights.count - 1]))

        // Quadratic curves through the midpoints of neighbouring points give a smooth surface with no kinks.
        var edge = Path()
        edge.move(to: points[0])
        for index in 1..<(points.count - 1) {
            let midpoint = CGPoint(
                x: (points[index].x + points[index + 1].x) / 2,
                y: (points[index].y + points[index + 1].y) / 2
            )
            edge.addQuadCurve(to: midpoint, control: points[index])
        }
        edge.addLine(to: points[points.count - 1])

        var fill = edge
        fill.addLine(to: CGPoint(x: size.width, y: size.height + 2))
        fill.addLine(to: CGPoint(x: 0, y: size.height + 2))
        fill.closeSubpath()

        return (fill, edge)
    }

    // MARK: - Private Helpers

    private func column(forX x: CGFloat, width: CGFloat) -> Int {
        guard width > 0 else { return 0 }
        let raw = Int(x / width * CGFloat(Self.columnCount))
        return min(max(raw, 0), Self.columnCount - 1)
    }

    private func add(_ amount: CGFloat, to column: Int, cap: CGFloat) {
        guard heights.indices.contains(column) else { return }
        heights[column] = min(cap, heights[column] + amount)
    }

    /// Lets slopes steeper than the angle of repose slump sideways. Snow is moved, never created or destroyed.
    private func relax(maxDifference: CGFloat) {
        for index in 0..<(heights.count - 1) {
            balance(index, index + 1, maxDifference: maxDifference)
        }

        // A second sweep in the other direction so slumping isn't biased to one side.
        for index in stride(from: heights.count - 2, through: 0, by: -1) {
            balance(index, index + 1, maxDifference: maxDifference)
        }
    }

    private func balance(_ first: Int, _ second: Int, maxDifference: CGFloat) {
        let difference = heights[first] - heights[second]
        let excess = abs(difference) - maxDifference
        guard excess > 0 else { return }

        let transfer = excess / 2 * (difference > 0 ? 1 : -1)
        heights[first] -= transfer
        heights[second] += transfer
    }
}
