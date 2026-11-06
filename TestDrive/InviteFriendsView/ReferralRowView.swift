//
//  ReferralRowView.swift
//  TestDrive
//

import SwiftUI

/// One row in the referral list: avatar, name, join date, optional "Remind them" action, and points.
struct ReferralRowView: View {
    private let referral: Referral

    // MARK: - Initializer

    /// Creates a row.
    /// - Parameter referral: The friend to display.
    init(referral: Referral) {
        self.referral = referral
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                Text(referral.name)
                    .font(.title3)

                Text("Joined \(referral.joinedText)")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if referral.canRemind {
                    Button { } label: {
                        Text("Remind them")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.inviteAccent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                CoinView(style: referral.canRemind ? .pending : .earned, size: 24)

                Text(referral.points.formatted(.number))
                    .font(.title3)
                    .foregroundStyle(referral.canRemind ? .secondary : .primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    // MARK: - Private Views

    private var avatar: some View {
        Circle()
            .fill(referral.avatarBackground)
            .frame(width: 84, height: 84)
            .overlay {
                Image(systemName: referral.symbolName)
                    .font(.system(size: 34))
                    .foregroundStyle(referral.avatarTint)
            }
            .overlay(alignment: .bottomTrailing) {
                if referral.canRemind {
                    Circle()
                        .fill(Color.inviteAccent)
                        .frame(width: 30, height: 30)
                        .overlay {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                        }
                        .overlay { Circle().stroke(.white, lineWidth: 2) }
                }
            }
    }
}

#Preview {
    ReferralRowView(
        referral: Referral(
            name: "Braden D.",
            joinedText: "Jun 3, 2026",
            points: 2_000,
            symbolName: "party.popper.fill",
            avatarBackground: .mint.opacity(0.3),
            avatarTint: .pink,
            canRemind: true
        )
    )
}
