//
//  BlockMode.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/14/25.
//

import Foundation

enum BlockMode: CaseIterable {
    case steps, rings, mindfulness

    var label: String {
        switch self {
        case .steps: return "Steps"
        case .rings: return "Rings"
        case .mindfulness: return "Mindfulness"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .rings: return "applewatch.watchface"
        case .mindfulness: return "brain.head.profile"
        }
    }
}
