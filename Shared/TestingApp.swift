//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    @AppStorage("selectedTab") private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ContentView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Sticky")
                    }
                    .tag(0)

                CornerSnapView()
                    .tabItem {
                        Image(systemName: "star")
                        Text("Snap")
                    }
                    .tag(1)
            }
        }
    }
}
