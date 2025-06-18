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
        VStack(spacing: 20) {
            Text("\(viewModel.value)")
                .font(.largeTitle)
            
            HStack(spacing: 20) {
                Button("-") {
                    viewModel.store.value -= 1
                }
                .buttonStyle(.borderedProminent)
                
                Button("+") {
                    viewModel.store.value += 1
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
