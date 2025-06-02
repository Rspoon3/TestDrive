//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var animate = false

    var body: some View {
        HStack {
            Image("spinAndWinBox")
                .resizable()
                .scaledToFit()
                .frame(width: 28)
                .padding(.leading, 11)

            Spacer()

            Text("6 Spins")
                .padding(.trailing, 13)
                .font(.footnote)
                .foregroundStyle(.white)
        }
        .frame(width: 118, height: 56)
        .background(Color.purple)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.blue, lineWidth: 3)
        )
        .overlay(
            // Animated shimmer overlay
            AngularGradient(
                gradient: Gradient(colors: [.clear, .white, .clear]),
                center: .center,
                angle: .degrees(animate ? 360 : 0)
            )
            .animation(
                Animation.linear(duration: 2).repeatForever(autoreverses: false),
                value: animate
            )
            .mask(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(lineWidth: 3)
            )
        )
        .onAppear {
            animate = true
        }
    }
}
#Preview {
    ContentView()
}
