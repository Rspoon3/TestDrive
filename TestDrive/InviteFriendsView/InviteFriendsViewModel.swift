//
//  InviteFriendsViewModel.swift
//  TestDrive
//

import SwiftUI
import UIKit

/// Owns the state for ``InviteFriendsView``. All data is mocked.
@MainActor
@Observable
final class InviteFriendsViewModel {
    /// The user's shareable invite code.
    let inviteCode = "RICKY!"

    /// Points per successful invite.
    let pointsPerInvite = 2_000

    /// Points waiting on friends to finish signing up.
    let inProgressPoints = 46_750

    /// Points already earned.
    let earnedPoints = 37_450

    /// The selected filter chip.
    var selectedTab: ReferralTab = .inProgress

    private let inProgressReferrals: [Referral]
    private let completedReferrals: [Referral]

    // MARK: - Initializer

    /// Creates the view model with mock referrals.
    init() {
        inProgressReferrals = [
            Referral(
                name: "Braden D.",
                joinedText: "Jun 3, 2026",
                points: 2_000,
                symbolName: "party.popper.fill",
                avatarBackground: Color(red: 0.78, green: 0.96, blue: 0.88),
                avatarTint: Color(red: 0.93, green: 0.36, blue: 0.55),
                canRemind: true
            ),
            Referral(
                name: "Gabrielle S.",
                joinedText: "Apr 29, 2025",
                points: 2_000,
                symbolName: "leaf.fill",
                avatarBackground: Color(red: 0.97, green: 0.88, blue: 0.98),
                avatarTint: Color(red: 0.45, green: 0.2, blue: 0.8),
                canRemind: true
            ),
            Referral(
                name: "john j.",
                joinedText: "Mar 12, 2025",
                points: 2_000,
                symbolName: "star.fill",
                avatarBackground: Color(red: 0.99, green: 0.9, blue: 0.9),
                avatarTint: Color(red: 0.93, green: 0.36, blue: 0.4),
                canRemind: true
            )
        ]

        completedReferrals = [
            Referral(
                name: "Maya R.",
                joinedText: "Jan 8, 2026",
                points: 2_000,
                symbolName: "music.note",
                avatarBackground: Color(red: 0.93, green: 0.88, blue: 0.99),
                avatarTint: Color(red: 0.45, green: 0.2, blue: 0.8),
                canRemind: false
            ),
            Referral(
                name: "Chris T.",
                joinedText: "Dec 19, 2025",
                points: 2_000,
                symbolName: "lightbulb.fill",
                avatarBackground: Color(red: 1, green: 0.97, blue: 0.7),
                avatarTint: Color(red: 0.95, green: 0.65, blue: 0.1),
                canRemind: false
            )
        ]
    }

    // MARK: - Public Helpers

    /// The referrals for the selected tab.
    var visibleReferrals: [Referral] {
        switch selectedTab {
        case .inProgress: inProgressReferrals
        case .completed: completedReferrals
        }
    }

    /// The number shown in a tab's badge, if it has one.
    /// - Parameter tab: The tab to count.
    /// - Returns: The count for the "In progress" tab, otherwise `nil`.
    func badgeCount(for tab: ReferralTab) -> Int? {
        switch tab {
        case .inProgress: 24
        case .completed: nil
        }
    }

    /// Copies the invite code to the pasteboard.
    func copyCode() {
        UIPasteboard.general.string = inviteCode
    }
}
