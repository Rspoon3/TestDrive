//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var weather = WeatherViewModel()
    @State private var selection: AppTab

    // MARK: - Initializer

    /// Pass `-tab weatherVFX` as a launch argument to open straight onto a tab.
    init() {
        let launched = UserDefaults.standard.string(forKey: "tab").flatMap(AppTab.init(rawValue:))
        _selection = State(initialValue: launched ?? .inviteFriends)
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selection) {
            Tab("Invite Friends", systemImage: "person.2", value: AppTab.inviteFriends) {
                InviteFriendsView()
                    .overlay { WeatherOverlayView(viewModel: weather) }
                    .overlay(alignment: .topTrailing) {
                        // Sits just left of the screen's edit button: 16pt margin + 52pt button + 12pt gap.
                        WeatherPickerView(viewModel: weather)
                            .padding(.trailing, 80)
                            .padding(.top, 4)
                    }
            }

            Tab("Weather VFX", systemImage: "cloud.bolt.rain.fill", value: AppTab.weatherVFX) {
                WeatherVFXTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
