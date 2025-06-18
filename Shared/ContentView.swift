//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = ThreadSafeIntegerStore()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(store.value)")
                .font(.largeTitle)
            
            HStack(spacing: 20) {
                Button("-") {
                    store.decrement()
                }
                .buttonStyle(.borderedProminent)
                
                Button("+") {
                    store.increment()
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
