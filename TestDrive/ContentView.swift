//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var weather = WeatherViewModel()

    var body: some View {
        InviteFriendsView()
            .overlay { WeatherOverlayView(viewModel: weather) }
            .overlay(alignment: .topTrailing) {
                // Sits just left of the screen's edit button: 16pt margin + 52pt button + 12pt gap.
                WeatherPickerView(viewModel: weather)
                    .padding(.trailing, 80)
                    .padding(.top, 4)
            }
    }
}

#Preview {
    ContentView()
}
