//
//  SettingsView.swift
//  TestDrive
//

import SwiftUI

/// Settings view for configuring photo comparison preferences.
struct SettingsView: View {
    @AppStorage("photoSpacing") private var photoSpacing: Double = 20
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Photo Spacing: \(Int(photoSpacing))", value: $photoSpacing, in: 0...50, step: 5)
                } header: {
                    Text("Comparison Layout")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
