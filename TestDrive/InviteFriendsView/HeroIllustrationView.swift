//
//  HeroIllustrationView.swift
//  TestDrive
//

import SwiftUI

/// The celebratory party-popper illustration at the top of the invite screen, approximated with shapes and SF Symbols.
struct HeroIllustrationView: View {
    // MARK: - Body

    var body: some View {
        ZStack {
            confetti
            sparkles
            popper
            flower
            bubble(symbol: "leaf.fill", tint: .green, background: Color(red: 0.78, green: 0.97, blue: 0.9), size: 76)
                .offset(x: -108, y: -34)
            avatarBubble
                .offset(x: -88, y: 40)
            bubble(symbol: "music.note", tint: .purple, background: Color(red: 0.97, green: 0.88, blue: 0.98), size: 86)
                .offset(x: 112, y: -50)
            bubble(symbol: "tree.fill", tint: .green, background: Color(red: 0.8, green: 0.95, blue: 0.6), size: 76)
                .offset(x: 52, y: 52)
            bubble(symbol: "lightbulb.fill", tint: .orange, background: Color(red: 1, green: 0.97, blue: 0.62), size: 76)
                .offset(x: 112, y: 92)
        }
        .frame(width: 320, height: 250)
    }

    // MARK: - Private Views

    private var popper: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 6,
            bottomLeadingRadius: 30,
            bottomTrailingRadius: 6,
            topTrailingRadius: 40
        )
        .fill(
            LinearGradient(
                colors: [Color(red: 0.62, green: 0.4, blue: 0.95), Color(red: 0.4, green: 0.2, blue: 0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: 70, height: 110)
        .rotationEffect(.degrees(-14))
        .offset(x: -6, y: 46)
    }

    private var flower: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color(red: 0.93, green: 0.36, blue: 0.62))
                    .frame(width: 54, height: 54)
                    .offset(y: -30)
                    .rotationEffect(.degrees(Double(index) * 72))
            }

            Circle()
                .fill(Color(red: 0.93, green: 0.36, blue: 0.62))
                .frame(width: 60, height: 60)

            CoinView(style: .earned, size: 52)
        }
        .offset(x: -2, y: -34)
    }

    private var sparkles: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 50))
                .foregroundStyle(.white)
                .offset(x: -64, y: -22)

            Image(systemName: "sparkle")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .offset(x: 82, y: 20)

            Image(systemName: "sparkle")
                .font(.system(size: 24))
                .foregroundStyle(Color(red: 1, green: 0.9, blue: 0.3))
                .offset(x: -82, y: -78)

            Image(systemName: "sparkle")
                .font(.system(size: 40))
                .foregroundStyle(Color(red: 1, green: 0.9, blue: 0.3))
                .offset(x: 62, y: -66)
        }
    }

    private var confetti: some View {
        ZStack {
            confettiPiece(color: Color(red: 0.93, green: 0.36, blue: 0.62), angle: 20)
                .offset(x: -96, y: -96)
            confettiPiece(color: Color(red: 1, green: 0.85, blue: 0.2), angle: -35)
                .offset(x: -90, y: 12)
            confettiPiece(color: Color(red: 0.93, green: 0.36, blue: 0.62), angle: 30)
                .offset(x: 118, y: 14)
            confettiPiece(color: Color(red: 1, green: 0.85, blue: 0.2), angle: -25)
                .offset(x: 18, y: 96)
        }
    }

    private var avatarBubble: some View {
        Circle()
            .fill(Color(white: 0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(white: 0.85))
            }
            .overlay { Circle().stroke(.white.opacity(0.9), lineWidth: 2) }
            .clipShape(.circle)
            .frame(width: 96, height: 96)
    }

    private func bubble(symbol: String, tint: Color, background: Color, size: CGFloat) -> some View {
        Circle()
            .fill(background)
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(tint)
            }
    }

    private func confettiPiece(color: Color, angle: Double) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 22, height: 26)
            .rotationEffect(.degrees(angle))
    }
}

#Preview {
    HeroIllustrationView()
        .padding()
        .background(Color(red: 0.38, green: 0.13, blue: 0.78))
}
