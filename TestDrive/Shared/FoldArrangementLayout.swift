//
//  FoldArrangementLayout.swift
//  TestDrive
//

import SwiftUI

/// Lays out an arrangement's primary and secondary around the fold's reserved region.
///
/// Around a partial fold the primary and secondary each take their own side: left and right in book pose,
/// top and bottom in laptop pose. Without a fold `unfolded` decides.
///
/// The primary is given `isArrangementSeparated`, so it can tell whether the secondary is shown beside it.
struct FoldArrangementLayout<Primary: View, Secondary: View>: View {
    /// How the views are arranged when there is no fold.
    enum Unfolded {
        /// Side by side when wide enough (regular width and landscape), otherwise only the primary shows.
        case split
        /// Only the primary shows.
        case primaryOnly
    }
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let unfolded: Unfolded
    private let primary: Primary
    private let secondary: Secondary
    
    // MARK: - Initializer
    
    init(unfolded: Unfolded, primary: Primary, secondary: Secondary) {
        self.unfolded = unfolded
        self.primary = primary
        self.secondary = secondary
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            Group {
                switch ArrangementFold(proxy) {
                case .book(let frame):
                    HStack(spacing: 0) {
                        separatedPrimary(true)
                            .frame(width: frame.minX)
                        
                        Color.clear
                            .frame(width: frame.width)
                        
                        secondary
                            .frame(maxWidth: .infinity)
                    }
                case .laptop(let frame):
                    VStack(spacing: 0) {
                        separatedPrimary(true)
                            .frame(height: frame.minY)
                        
                        Color.clear
                            .frame(height: frame.height)
                        
                        secondary
                            .frame(maxHeight: .infinity)
                    }
                case nil:
                    unfoldedLayout(isLandscape: proxy.size.width > proxy.size.height)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private func unfoldedLayout(isLandscape: Bool) -> some View {
        if unfolded == .split, horizontalSizeClass != .compact, isLandscape {
            HStack(spacing: 0) {
                separatedPrimary(true)
                    .frame(maxWidth: .infinity)
                
                secondary
                    .frame(maxWidth: .infinity)
            }
        } else {
            separatedPrimary(false)
        }
    }
    
    private func separatedPrimary(_ isSeparated: Bool) -> some View {
        primary.environment(\.isArrangementSeparated, isSeparated)
    }
}
