//
//  ProgressRow.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/14/25.
//

import SwiftUI

struct ProgressRow: View {
    let title: String
    let value: Double
    let goal: Double
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading) {
            Label("\(title): \(Int(value)) / \(Int(goal))", systemImage: systemImage)
                .font(.subheadline)

            ProgressView(value: value, total: goal)
                .accentColor(.blue)
        }
    }
}
