//
//  ActivityRingViewRepresentable.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/12/25.
//


import SwiftUI
import HealthKit
import HealthKitUI

struct ActivityRingViewRepresentable: UIViewRepresentable {
    let summary: HKActivitySummary

    func makeUIView(context: Context) -> HKActivityRingView {
        return HKActivityRingView()
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.setActivitySummary(summary, animated: true)
    }
}