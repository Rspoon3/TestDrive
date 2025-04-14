//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    private let stepGoalMonitor = StepGoalMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? await stepGoalMonitor.requestNotifications()
                    stepGoalMonitor.startMonitoring()
                }
        }
    }
}
