//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Sticky")
                    }
                
                CornerSnapView()
                    .tabItem {
                        Image(systemName: "star")
                        Text("Snap")
                    }
            }
        }
    }
}
