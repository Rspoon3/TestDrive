//
//  AppModel.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/11/25.
//

import FamilyControls
import ManagedSettings
import DeviceActivity
import Foundation

// MARK: - Main Model
//@MainActor
class AppModel: ObservableObject {
    static let shared = AppModel()
    
    @Published var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Authorization failed: \(error)")
        }
    }
    func blockForALittle() {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let end = Calendar.current.dateComponents([.hour, .minute], from: Date().addingTimeInterval(30 * 60)) // 5 min later

        let schedule = DeviceActivitySchedule(
            intervalStart: now,
            intervalEnd: end,
            repeats: false
        )

        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(.init("testing"), during: schedule)
            print("🟢 Monitoring scheduled for 5 minutes")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    func startEvenHourMonitoringV0() {
        let evenHours = Array(stride(from: 0, through: 10, by: 1))
        
        for hour in evenHours {
            let endHour = hour + 1
            
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: hour, minute: 0),
                intervalEnd: DateComponents(hour: endHour, minute: 0),
                repeats: true
            )
            
            let center = DeviceActivityCenter()
            do {
                try center.startMonitoring(DeviceActivityName("EvenHour-\(hour)"), during: schedule)
                print("Monitoring scheduled for \(hour):00–\(endHour):00")
            } catch {
                print("Failed to start monitoring for \(hour): \(error)")
            }
        }
    }
    
    func applyShielding() {
        store.shield.applications = selection.applicationTokens
        
    }
    
    func clearShielding() {
        store.shield.applications = nil
    }
}
