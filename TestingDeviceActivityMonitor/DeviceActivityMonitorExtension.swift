//
//  DeviceActivityMonitorExtension.swift
//  TestingDeviceActivityMonitor
//
//  Created by Ricky Witherspoon on 4/11/25.
//

import DeviceActivity
import ManagedSettings

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("🔄 Reapplying shields for new day")
        let tokens = AppModel.shared.savedAppTokens
        store.shield.applications = tokens
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("🔓 Unblocking apps for: \(activity.rawValue)")
        store.shield.applications = nil
    }
}
