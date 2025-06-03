//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var animate = false
    @State private var state: ExpandedState = .collapsed
    @State private var showCount = false
    @State private var trapOffset: CGFloat = 0
    private let height: CGFloat = 56
    private let cornerRadius: CGFloat = 22
    private let darkPurple = Color(red: 55/255, green: 17/255, blue: 100/255)
    
    enum ExpandedState {
        case collapsed
        case withText
        case boxOnly
        
        var width: CGFloat {
            switch self {
            case .collapsed:
                return 3
            case .withText:
                return 124
            case .boxOnly:
                return 56
            }
        }
    }

    var body: some View {
        VStack(spacing: 100) {
            Button("Toggle") {
                guard state == .collapsed else { return }
                
                withAnimation(.linear(duration: 1.2)) {
                    state = .withText
                    Task {
                        try await Task.sleep(for: .seconds(1.2))
                        withAnimation(.linear(duration: 1)) {
                            trapOffset = -164
                        }
                        
                        try await Task.sleep(for: .seconds(6))
                        
                        withAnimation(.linear(duration: 0.8)) {
                            state = .boxOnly
                        }
                        
                        try await Task.sleep(for: .seconds(1.8))
                        
                        withAnimation(.linear(duration: 0.8)) {
                            showCount = true
                        }
                    }
                }
            }
            
            // Align to trailing to make it expand leftward
            HStack {
                Spacer()
                
                ZStack(alignment: .bottomTrailing) {
                    spinAndWinFAB
                        .onTapGesture {
                            print("Tap")
                        }
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
        .frame(height: height)
        .mask(alignment: .leading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: state.width)
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
            width: state.width,
            height: height,
            alignment: .leading
        )
        .background(darkPurple)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            AngularGradient(
                gradient: Gradient(colors: [.purple, .purple, .white]),
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
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3))
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
