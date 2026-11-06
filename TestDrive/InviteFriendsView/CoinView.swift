//
//  CoinView.swift
//  TestDrive
//

import SwiftUI

/// A small points coin, either gold (earned) or muted (pending).
struct CoinView: View {
    /// The coin's color treatment.
    enum Style {
        case earned
        case pending
        case pendingOnDark
    }

    private let style: Style
    private let size: CGFloat

    // MARK: - Initializer

    /// Creates a coin.
    /// - Parameters:
    ///   - style: Gold when earned, muted when pending.
    ///   - size: Diameter in points.
    init(style: Style, size: CGFloat) {
        self.style = style
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Circle()
                .fill(rimColor)

            Circle()
                .fill(faceColor)
                .padding(size * 0.1)

            Image(systemName: "multiply")
                .font(.system(size: size * 0.45, weight: .black))
                .foregroundStyle(glyphColor)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Private Helpers

    private var rimColor: Color {
        switch style {
        case .earned: Color(red: 1, green: 0.8, blue: 0.4)
        case .pending: Color(white: 0.8)
        case .pendingOnDark: Color.white.opacity(0.85)
        }
    }

    private var faceColor: Color {
        switch style {
        case .earned: Color(red: 0.97, green: 0.58, blue: 0.2)
        case .pending: Color(white: 0.6)
        case .pendingOnDark: Color(red: 0.55, green: 0.4, blue: 0.85)
        }
    }

    private var glyphColor: Color {
        switch style {
        case .earned: .white
        case .pending: Color(white: 0.85)
        case .pendingOnDark: .white
        }
    }
}

#Preview {
    HStack {
        CoinView(style: .earned, size: 40)
        CoinView(style: .pending, size: 40)
        CoinView(style: .pendingOnDark, size: 40)
    }
    .padding()
    .background(.purple)
}
