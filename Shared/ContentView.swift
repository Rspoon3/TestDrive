//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("IntStore Value: \(viewModel.value)")
                    .font(.title)

                HStack(spacing: 20) {
                    Button("-") {
                        viewModel.decrementIntStore()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("+") {
                        viewModel.incrementIntStore()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Divider()

            VStack(spacing: 20) {
                Text("MultiDataStore.int: \(viewModel.multiValue)")
                    .font(.title2)

                HStack(spacing: 20) {
                    Button("-") {
                        viewModel.decrementMulti()
                    }
                    .buttonStyle(.bordered)

                    Button("+") {
                        viewModel.incrementMulti()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
