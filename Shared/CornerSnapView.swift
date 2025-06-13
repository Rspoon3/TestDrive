//
//  CornerSnapView.swift
//  Shared
//
//  Created by Richard Witherspoon on 6/13/25.
//

import SwiftUI
import Foundation

struct CornerSnapView: View {
    @State private var circlePosition: CGPoint = CGPoint(x: 100, y: 100)
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: "star.circle.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundStyle(.white, .blue)
                .position(circlePosition)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            let velocity = value.velocity
                            
                            // Calculate final position (base position + drag offset)
                            let finalX = circlePosition.x + dragOffset.width
                            let finalY = circlePosition.y + dragOffset.height
                            
                            // Predict final position based on velocity
                            let predictedX = finalX + velocity.width * 0.1
                            let predictedY = finalY + velocity.height * 0.1
                            
                            // Find nearest corner
                            let nearestCorner = findNearestCorner(
                                predictedPosition: CGPoint(x: predictedX, y: predictedY),
                                in: geometry.size
                            )
                            
                            // Animate to corner
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                circlePosition = nearestCorner
                                dragOffset = .zero
                            }
                        }
                )
        }
        .onAppear {
            // Start in top-right corner
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let safeArea = window.safeAreaInsets
                    let screenSize = window.bounds.size
                    circlePosition = CGPoint(
                        x: screenSize.width - safeArea.right - 44,
                        y: safeArea.top + 44
                    )
                }
            }
        }
    }
    
    private func findNearestCorner(predictedPosition: CGPoint, in size: CGSize) -> CGPoint {
        let margin: CGFloat = 44
        let safeMargin: CGFloat = 50
        
        let corners = [
            CGPoint(x: margin, y: safeMargin), // Top-left
            CGPoint(x: size.width - margin, y: safeMargin), // Top-right
            CGPoint(x: margin, y: size.height - safeMargin), // Bottom-left
            CGPoint(x: size.width - margin, y: size.height - safeMargin) // Bottom-right
        ]
        
        return corners.min { corner1, corner2 in
            distance(from: predictedPosition, to: corner1) < distance(from: predictedPosition, to: corner2)
        } ?? corners[0]
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
}

#Preview {
    CornerSnapView()
}
