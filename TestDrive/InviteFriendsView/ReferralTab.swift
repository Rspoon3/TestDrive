//
//  ReferralTab.swift
//  TestDrive
//

/// The filter chips above the referral list.
enum ReferralTab: String, CaseIterable, Identifiable {
    case inProgress = "In progress"
    case completed = "Completed"

    var id: String { rawValue }
}
