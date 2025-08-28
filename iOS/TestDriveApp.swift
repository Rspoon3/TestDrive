//
//  TestDriveApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestDriveApp: App {
    @State private var deepLinkURL: URL?
    
    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkURL: $deepLinkURL)
                .onOpenURL { url in
                    print("Received deep link: \(url)")
                    deepLinkURL = url
                }
        }
    }
}
