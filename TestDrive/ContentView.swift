//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Body
    
    var body: some View {
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
        }
    }
}

#Preview {
    ContentView()
}
