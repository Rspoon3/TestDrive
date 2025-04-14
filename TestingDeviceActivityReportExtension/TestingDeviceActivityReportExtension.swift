//
//  TestingDeviceActivityReportExtension.swift
//  TestingDeviceActivityReportExtension
//
//  Created by Ricky Witherspoon on 4/13/25.
//

import DeviceActivity
import SwiftUI

@main
struct TestingDeviceActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
