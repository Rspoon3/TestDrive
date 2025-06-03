//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var animate = false
    @State private var showText = true
    
    var body: some View {
        VStack(spacing: 100) {
            Button("Toggle") {
                withAnimation(.linear(duration: 0.2)) {
                    showText.toggle()
                }
            }
            
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(style: StrokeStyle(lineWidth: 3))
                .foregroundStyle(.blue)
                .frame(width: 124, height: 56)
            
            
            // Align to trailing to make it expand leftward
            HStack {
                Spacer()
                spinAndWinFAB
            }
            
            Spacer()
        }
    }
    
    private var spinAndWinFAB: some View {
        HStack(spacing: 12) {
            Image("spinAndWinBox")
                .resizable()
                .scaledToFit()
                .frame(width: 28)
                .padding(.leading, 14)
            
            Text("6 Spins")
                .fixedSize()
                .font(.footnote)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(
            width: showText ? 124 : 56,
            height: 56,
            alignment: .leading
        )
        .background(Color.purple)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            AngularGradient(
                gradient: Gradient(colors: [.blue, .blue, .white]),
                center: .center,
                angle: .degrees(animate ? 360 : 0)
            )
            .animation(
                Animation.linear(duration: 1.2)
                    .delay(5)
                    .repeatForever(autoreverses: false),
                value: animate
            )
            .mask(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3))
                    .foregroundStyle(.blue)
            )
        }
        .onAppear {
            animate.toggle()
        }
    }
}

#Preview {
    ContentView()
}
