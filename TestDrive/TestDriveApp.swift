//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

@main
struct TestDriveApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Basic", systemImage: "b.circle") {
                    BasicArrangementView()
                }
                
                Tab("Stacked", systemImage: "s.circle") {
                    StackedScrollSampleView()
                }
                
                Tab("Overlay", systemImage: "o.circle") {
                    OverlaySampleView()
                }
                
                Tab("Custom S", systemImage: "s.square") {
                    CustomStackedSampleView()
                }
                
                Tab("Custom O", systemImage: "o.square") {
                    CustomOverlaySampleView()
                }
            }
        }
    }
}
