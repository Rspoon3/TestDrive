//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView_: View {
    @StateObject private var viewStore = IntStore.shared
    
    var body: some View {
        Button(viewStore.value.formatted()) {
            viewStore.value += 1
        }
        .font(.largeTitle)
    }
}

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
                    
                    .onAppear {
                        DispatchQueue.global(qos: .userInitiated).async {
                            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                                viewModel.mutateIncrementIntStore()
                            }
                        }
                    }
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
                
                
                Toggle("MultiDataStore.bool", isOn: $viewModel.multiBool)
                    .toggleStyle(.switch)
                    .padding(.top, 10)
            }
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
