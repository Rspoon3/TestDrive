//
//  TestDriveApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    init() {
        // Swizzle UIViewController's present method to add haptics when sheets are shown
        UIViewController.swizzlePresentMethod()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
