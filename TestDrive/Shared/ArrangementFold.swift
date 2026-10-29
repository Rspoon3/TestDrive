//
//  ArrangementFold.swift
//  TestDrive
//

import SwiftUI

/// A partial fold dividing an iPhone Duo's display, with the region the fold occupies.
enum ArrangementFold: Equatable {
    /// A vertical fold, with the views side by side.
    case book(CGRect)
    /// A horizontal fold, with the views stacked.
    case laptop(CGRect)
    
    /// Reads the active fold from a geometry proxy, or `nil` when flat, closed, or not a folding iPhone.
    init?(_ proxy: GeometryProxy) {
        guard
            let region = proxy.reservedRegions(kind: .division, options: .includeInactive).first,
            region.isActive
        else {
            return nil
        }
        
        self = region.frame.height > region.frame.width
            ? .book(region.frame)
            : .laptop(region.frame)
    }
}
