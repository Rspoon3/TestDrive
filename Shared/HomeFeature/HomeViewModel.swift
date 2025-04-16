//
//  HomeViewModel.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import SwiftUI
import HealthKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import OSLog
import SwiftTools

@MainActor
@Observable
final class HomeViewModel {
    private let logger = Logger(category: HomeViewModel.self)
    private let healthKitManager = HealthKitManager()
    private let userDefaults = UserDefaults.shared
    private let managedSettingsStore = ManagedSettingsStore()
    private(set) var metrics = HealthKitMetrics()
    private let center = DeviceActivityCenter()
    private(set) var savedAppTokens: Set<ApplicationToken> = []
    var showPicker = false
    
    var familyActivitySelection = FamilyActivitySelection() {
        didSet {
            saveActivitySelection(familyActivitySelection)
            self.savedAppTokens = familyActivitySelection.applicationTokens
            
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    var stepGoal: Int {
        didSet {
            userDefaults.set(stepGoal, forKey: "stepGoal")
            
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    var mindfulnessGoal: Int {
        didSet {
            userDefaults.set(mindfulnessGoal, forKey: "mindfulnessGoal")
            
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    var selectedBlockModes: Set<BlockMode> {
        didSet {
            let rawValues = selectedBlockModes.map { $0.rawValue }
            userDefaults.set(rawValues, forKey: "selectedBlockModes")
            
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }

    var skipOption: SkipOption {
        didSet {
            userDefaults.set(skipOption.rawValue, forKey: "skipOption")
        }
    }

    // MARK: - Init

    init() {
        // Load selectedBlockModes
        if let rawValues = userDefaults.array(forKey: "selectedBlockModes") as? [Int] {
            let modes = rawValues.compactMap { BlockMode(rawValue: $0) }
            selectedBlockModes = Set(modes.isEmpty ? [.steps] : modes)
        } else {
            selectedBlockModes = [.steps, .mindfulness]
        }

        // Load skipOption
        if let raw = userDefaults.object(forKey: "skipOption") as? Int,
           let option = SkipOption(rawValue: raw) {
            skipOption = option
        } else {
            skipOption = .five
        }
        
        self.stepGoal = userDefaults.integer(forKey: "stepGoal")
        self.mindfulnessGoal = userDefaults.integer(forKey: "mindfulnessGoal")
        
        // Provide defaults if not set
        if stepGoal == 0 { stepGoal = 10_000 }
        if mindfulnessGoal == 0 { mindfulnessGoal = 5 }
        
        if let restored = loadActivitySelection() {
            self.familyActivitySelection = restored
            self.savedAppTokens = restored.applicationTokens
        }
    }
    
    // MARK: - Public Helpers
    
    func toggleBlockMode(_ mode: BlockMode) {
        withAnimation(.bouncy) {
            if selectedBlockModes.contains(mode) {
                guard selectedBlockModes.count > 1 else { return }
                selectedBlockModes.remove(mode)
            } else {
                selectedBlockModes.insert(mode)
            }
        }
    }
    
    func evaluateProgressAndShieldApps() async throws {
        try await fetchNeededHealthKitMetrics()
        scheduleDailyRingReset()
        changeBlockStatusIfNeeded()
    }
    
    // MARK: - Private
    
    private func fetchNeededHealthKitMetrics() async throws {
        metrics = try await withThrowingTaskGroup(of: HealthKitMetricResult.self) { group in
            var collected = HealthKitMetrics()

            if selectedBlockModes.contains(.steps) {
                group.addTask {
                    let count = try await self.healthKitManager.stepCount()
                    return .stepCount(count)
                }
            } else {
                metrics.stepCount = nil
            }

            if selectedBlockModes.contains(.mindfulness) {
                group.addTask {
                    let minutes = try await self.healthKitManager.mindfulnessMinutes()
                    return .mindfulnessMinutes(minutes)
                }
            } else {
                metrics.mindfulnessMinutes = nil
            }

            if selectedBlockModes.contains(.rings) {
                group.addTask {
                    let rings = try await self.healthKitManager.rings()
                    return .ringValues(rings)
                }
            } else {
                metrics.ringValues = nil
            }

            for try await result in group {
                switch result {
                case .stepCount(let count):
                    collected.stepCount = count
                case .mindfulnessMinutes(let minutes):
                    collected.mindfulnessMinutes = minutes
                case .ringValues(let values):
                    collected.ringValues = values
                }
            }

            return collected
        }
    }
    
    private func scheduleDailyRingReset() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(DeviceActivityName("DailyRingReset"), during: schedule)
            logger.debug("✅ Scheduled daily app blocking reset")
        } catch {
            logger.debug("❌ Failed to start monitoring: \(error)")
        }
    }
    
    private func changeBlockStatusIfNeeded() {
        let conditionsMet = selectedBlockModes.allSatisfy { mode in
            switch mode {
            case .mindfulness:
                return (metrics.mindfulnessMinutes ?? 0) >= mindfulnessGoal
            case .rings:
                return metrics.ringValues?.allClosed ?? false
            case .steps:
                return (metrics.stepCount ?? 0) >= stepGoal
            }
        }
        
        if conditionsMet {
            logger.debug("🎉 Goal met — unblocking apps")
            managedSettingsStore.shield.applications = nil
        } else {
            logger.debug("🔒 No goal met — applying shield")
            managedSettingsStore.shield.applications = savedAppTokens
        }
    }
    
    // MARK: - Apple-style persistence

    private func saveActivitySelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.shared.set(data, forKey: "SavedActivitySelection")
        } catch {
            logger.debug("❌ Failed to encode selection: \(error)")
        }
    }

    private func loadActivitySelection() -> FamilyActivitySelection? {
        guard let data = UserDefaults.shared.data(forKey: "SavedActivitySelection") else { return nil }

        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            logger.debug("❌ Failed to decode selection: \(error)")
            return nil
        }
    }
}
