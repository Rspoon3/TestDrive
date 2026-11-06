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
            .overlay(alignment: .bottom) { WeatherPickerView(viewModel: weather) }
    }
}

#Preview {
    ContentView()
}
