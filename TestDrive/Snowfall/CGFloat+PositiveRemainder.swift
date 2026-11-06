//
//  CGFloat+PositiveRemainder.swift
//  TestDrive
//

import CoreGraphics

extension CGFloat {
    /// A remainder that is never negative, so particles pushed off the left edge wrap to the right.
    /// - Parameter divisor: The length of the loop.
    func positiveRemainder(dividingBy divisor: CGFloat) -> CGFloat {
        let remainder = truncatingRemainder(dividingBy: divisor)
        return remainder < 0 ? remainder + divisor : remainder
    }
}
