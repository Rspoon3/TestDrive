//
//  QuickExportRange.swift
//  TestDrive
//

import Foundation

/// Preset look-back windows for one-tap health data exports.
enum QuickExportRange: CaseIterable, Identifiable {
    case thirtyDays
    case ninetyDays
    case oneEightyDays
    case oneYear

    var id: Self { self }

    /// The button title for the range.
    var title: String {
        switch self {
        case .thirtyDays: "30 Days"
        case .ninetyDays: "90 Days"
        case .oneEightyDays: "180 Days"
        case .oneYear: "1 Year"
        }
    }

    /// The date the range starts at, relative to now.
    var startDate: Date {
        let calendar = Calendar.current
        let component: (Calendar.Component, Int) = switch self {
        case .thirtyDays: (.day, -30)
        case .ninetyDays: (.day, -90)
        case .oneEightyDays: (.day, -180)
        case .oneYear: (.year, -1)
        }
        return calendar.date(byAdding: component.0, value: component.1, to: .now) ?? .now
    }
}
