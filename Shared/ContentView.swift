//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

// MARK: - Activity Name
extension DeviceActivityName {
    static let oddHours = Self("OddHours")
}


// MARK: - UI
struct ContentView: View {
    @StateObject var model = AppModel.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Apps to Block")
                .font(.title2)
                .bold()
            
            FamilyActivityPicker(selection: $model.selection)
                .frame(height: 300)
            
            Button("Start Odd-Hour Blocking") {
                model.applyShielding()
                model.blockForALittle()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Clear Blocking") {
                model.clearShielding()
            }
            .foregroundColor(.red)
        }
        .padding()
        .task {
            await model.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
