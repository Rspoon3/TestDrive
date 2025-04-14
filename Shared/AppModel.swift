import Foundation
import FamilyControls
import ManagedSettings
import HealthKit
import DeviceActivity

//@MainActor
class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var activitySummary: HKActivitySummary?
    @Published var selection = FamilyActivitySelection() {
        didSet {
            saveActivitySelection(selection)
            self.savedAppTokens = selection.applicationTokens
        }
    }

    private(set) var savedAppTokens: Set<ApplicationToken> = []
    private let store = ManagedSettingsStore()
    private let healthStore = HKHealthStore()

    init() {
        if let restored = loadActivitySelection() {
            self.selection = restored
            self.savedAppTokens = restored.applicationTokens
        }
        requestAuthorization()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                try await requestHealthKitAuthorization()
            } catch {
                print("❌ Authorization failed: \(error)")
            }
        }
    }
    
    func requestHealthKitAuthorization() async throws {
        let typesToRead: Set = [
            HKObjectType.activitySummaryType(),
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        try await healthStore.requestAuthorization(toShare: Set(), read: Set(typesToRead))
        
        let ringsClosed = try await areRingsClosed(healthStore: healthStore)
        let stepsGoalMet = try await hasMetStepGoal(goal: 10_000)
        
        if ringsClosed || stepsGoalMet {
            print("🎉 Goal met — unblocking apps")
            store.shield.applications = nil
        } else {
            print("🔒 No goal met — applying shield")
            store.shield.applications = savedAppTokens
        }
        
        scheduleDailyRingReset()
    }

    // MARK: - Ring Status + Shield Logic

    func unblockAll() {
        self.store.shield.applications = nil
    }

    func areRingsClosed(healthStore: HKHealthStore) async throws -> Bool {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.calendar = Calendar.current

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: components, end: components)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                DispatchQueue.main.async {
                    self.activitySummary = summaries?.first
                }

                guard let summary = summaries?.first else {
                    continuation.resume(returning: false)
                    return
                }

                let move = summary.activeEnergyBurned.doubleValue(for: .kilocalorie())
                let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())

                let exercise = summary.appleExerciseTime.doubleValue(for: .minute())
                let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())

                let stand = summary.appleStandHours.doubleValue(for: .count())
                let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())

                let allClosed = move >= moveGoal && exercise >= exerciseGoal && stand >= standGoal
                continuation.resume(returning: allClosed)
            }

            healthStore.execute(query)
        }
    }
    
    func hasMetStepGoal(goal: Double) async throws -> Bool {
        let healthStore = HKHealthStore()
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let quantity = result?.sumQuantity() else {
                    continuation.resume(returning: false)
                    return
                }

                let steps = quantity.doubleValue(for: .count())
                print("📊 Steps today: \(Int(steps)) / \(Int(goal))")
                continuation.resume(returning: steps >= goal)
            }

            healthStore.execute(query)
        }
    }

    func scheduleDailyRingReset() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )

        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(DeviceActivityName("DailyRingReset"), during: schedule)
            print("✅ Scheduled daily app blocking reset")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    // MARK: - Apple-style persistence

    private func saveActivitySelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: "SavedActivitySelection")
        } catch {
            print("❌ Failed to encode selection: \(error)")
        }
    }

    private func loadActivitySelection() -> FamilyActivitySelection? {
        guard let data = UserDefaults.standard.data(forKey: "SavedActivitySelection") else { return nil }

        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("❌ Failed to decode selection: \(error)")
            return nil
        }
    }
}
