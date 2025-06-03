//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var animate = false
    @State private var showText = false
    @State private var showCount = false
    @State private var trapOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 100) {
            Button("Toggle") {
                withAnimation(.linear(duration: 1.2)) {
                    showText.toggle()
//                    showCount.toggle()
                    trapOffset = trapOffset == 0 ? -164 : 0
                }
            }
            
            // Align to trailing to make it expand leftward
            HStack {
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    spinAndWinFAB
                    .overlay(alignment: .leading) {
                        trap
                    }
                    
                    circleDot
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var circleDot: some View {
        Circle()
            .foregroundStyle(.red)
            .overlay {
                Text("6")
                    .foregroundStyle(.white)
                    .font(.caption)
            }
            .frame(width: 20)
            .opacity(showCount ? 1 : 0)
            .scaleEffect(showCount ? 1 : 0.6)
            .zIndex(showCount ? 1 : 0)
            .animation(
                .spring(
                    duration: 0.4,
                    bounce: 0.73,
                    blendDuration: 0.71
                ),
                value: showCount
            )
            .offset(x: 4, y: 4)
    }
    
    private var trap: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 124)
            RightSlantTriangle()
                .frame(width: 40)
        }
        .offset(x: trapOffset)
        .foregroundStyle(.purple)
        .frame(height: 56)
        .mask(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22)
                .frame(width: showText ? 124 : 56)
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

struct RightLeaningTrapezoid: Shape {
    var lean: CGFloat = 20 // positive value = right lean

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + lean, y: rect.minY))         // top-left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))             // top-right
        path.addLine(to: CGPoint(x: rect.maxX - lean, y: rect.maxY))      // bottom-right
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))             // bottom-left
        path.closeSubpath()

        return path
    }
}

struct RightSlantTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))      // top-left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))   // top-right
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))   // bottom-left
        path.closeSubpath()

        return path
    }
}
