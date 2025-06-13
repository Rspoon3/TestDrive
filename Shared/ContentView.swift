//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var buttonOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        NavigationStack {
            Image(systemName: "star.circle.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .padding([.trailing, .bottom])
                .foregroundStyle(.white, .blue)
                .offset(buttonOffset)
//                .scaleEffect(isDragging ? 1.1 : 1.0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let maxDistance: CGFloat = 60
                            let resistance: CGFloat = 0.4
                            
                            let dampedX = value.translation.width * resistance
                            let dampedY = value.translation.height * resistance
                            
                            let distance = sqrt(dampedX * dampedX + dampedY * dampedY)
                            let scale = min(maxDistance / max(distance, 1), 1.0)
                            
                            buttonOffset = CGSize(
                                width: dampedX * scale,
                                height: dampedY * scale
                            )
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                buttonOffset = .zero
                            }
                        }
                )
        }
    }
}

#Preview {
    ContentView()
}
