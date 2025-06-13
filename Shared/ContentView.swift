//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(0..<100, id: \.self) { _ in
                    Color.red
                        .frame(height: 140)
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                Button {
                    
                } label: {
                    Image(systemName: "star.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .padding([.trailing, .bottom])
                        .foregroundStyle(.white, .blue)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
