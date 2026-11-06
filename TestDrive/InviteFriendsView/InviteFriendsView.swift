//
//  InviteFriendsView.swift
//  TestDrive
//

import SwiftUI

/// A UI-only recreation of the "Invite friends" screen: a purple header with stats, invite code, and share actions,
/// above a white list of referrals.
struct InviteFriendsView: View {
    @State private var viewModel: InviteFriendsViewModel

    // MARK: - Initializer

    /// Creates the screen.
    /// - Parameter viewModel: Supplies the mocked data. Pass `nil` to create a fresh one.
    @MainActor
    init(viewModel: InviteFriendsViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? InviteFriendsViewModel())
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .background(Color.inviteBackground.ignoresSafeArea(edges: .top))

                referralList
                    .background(.background)
            }
        }
        .background(.background)
        .overlay(alignment: .top) { navigationButtons }
    }

    // MARK: - Private Views

    private var navigationButtons: some View {
        HStack {
            circleButton(symbol: "chevron.left")
                .frame(maxWidth: .infinity, alignment: .leading)

            circleButton(symbol: "square.and.pencil")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HeroIllustrationView()
                .padding(.top, 56)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text("Get")
                    CoinView(style: .earned, size: 38)
                    Text("\(viewModel.pointsPerInvite.formatted(.number)) per invite")
                }
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)

                Text("Get a bonus when friends sign up for Fetch using your code and start earning in the app.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.top, 36)
            .padding(.horizontal, 24)

            stats
                .padding(.top, 36)

            inviteCodeCard
                .padding(.top, 36)
                .padding(.horizontal, 16)

            actionButtons
                .padding(.top, 14)
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
        }
    }

    private var stats: some View {
        HStack(spacing: 0) {
            statColumn(title: "In progress", value: viewModel.inProgressPoints, coin: .pendingOnDark, dimmed: true)

            Divider()
                .overlay(.white.opacity(0.2))
                .frame(height: 56)

            statColumn(title: "Earned", value: viewModel.earnedPoints, coin: .earned, dimmed: false)
        }
    }

    private var inviteCodeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invite code")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))

                Text(viewModel.inviteCode)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button { viewModel.copyCode() } label: {
                Image(systemName: "square.on.square")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(.white.opacity(0.12), in: .rect(cornerRadius: 10))
        .overlay { RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.25), lineWidth: 1) }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button { } label: {
                Label("View code", systemImage: "qrcode")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .overlay { RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 1.5) }
            }

            Button { } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.white, in: .rect(cornerRadius: 8))
            }
        }
        .buttonStyle(.plain)
    }

    private var referralList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(ReferralTab.allCases) { tab in
                    tabChip(tab)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            ForEach(viewModel.visibleReferrals) { referral in
                ReferralRowView(referral: referral)

                Divider()
            }
        }
    }

    private func circleButton(symbol: String) -> some View {
        Button { } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.black.opacity(0.45), in: .circle)
        }
        .buttonStyle(.plain)
    }

    private func statColumn(title: String, value: Int, coin: CoinView.Style, dimmed: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 8) {
                CoinView(style: coin, size: 34)

                Text(value.formatted(.number))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white.opacity(dimmed ? 0.7 : 1))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tabChip(_ tab: ReferralTab) -> some View {
        let isSelected = viewModel.selectedTab == tab

        return Button {
            viewModel.selectedTab = tab
        } label: {
            HStack(spacing: 6) {
                Text(tab.rawValue)

                if let count = viewModel.badgeCount(for: tab) {
                    Text("\(count)")
                        .fontWeight(.semibold)
                }
            }
            .font(.title3)
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? Color(red: 1, green: 0.96, blue: 0.84) : .clear, in: .capsule)
            .overlay {
                Capsule()
                    .stroke(
                        isSelected ? Color(red: 0.92, green: 0.35, blue: 0.25) : Color(white: 0.85),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InviteFriendsView()
}
