//
//  GradientTest.swift
//  Testing
//
//  Created by Ricky Witherspoon on 7/25/25.
//

import SwiftUI

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(startAngle.radians, endAngle.radians)
        }
        set {
            startAngle = Angle(radians: newValue.first)
            endAngle = Angle(radians: newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        // Use diagonal length to ensure we fill the entire rectangle
        let radius = sqrt(rect.width * rect.width + rect.height * rect.height)
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct GradientTest: View {
    // Animation configuration
    let rotationDuration: Double
    let pauseDuration: Double
    let maxSliceWidth: Double
    let convergenceAngle: Double
    let gradientColors: [Color]
    
    init(
        rotationDuration: Double = 6.0,
        pauseDuration: Double = 2.0,
        maxSliceWidth: Double = 90.0,
        convergenceAngle: Double = 0.0,
        gradientColors: [Color] = [.white, .purple]
    ) {
        self.rotationDuration = rotationDuration
        self.pauseDuration = pauseDuration
        self.maxSliceWidth = maxSliceWidth
        self.convergenceAngle = convergenceAngle
        self.gradientColors = gradientColors
    }
    
    func calculateAnimationValues(for progress: Double) -> (rotation: Double, sliceWidth: Double) {
        let totalDuration = rotationDuration + pauseDuration
        let animationPhaseRatio = rotationDuration / totalDuration
        
        if progress < animationPhaseRatio {
            let animationProgress = progress / animationPhaseRatio
            let rotation = animationProgress * 360
            // Adjust sine wave so width is 0 at start and end
            let sliceWidth = sin(animationProgress * .pi) * maxSliceWidth
            return (rotation, sliceWidth)
        } else { // Pause phase
            return (convergenceAngle, 0)
        }
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let cycleDuration = rotationDuration + pauseDuration
            let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
            
            let values = calculateAnimationValues(for: cycleProgress)
            
            Group {
                if values.sliceWidth > 0 {
                    PieSlice(
                        startAngle: .degrees(values.rotation - values.sliceWidth/2),
                        endAngle: .degrees(values.rotation + values.sliceWidth/2)
                    )
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: .center,
                            startAngle: .degrees(values.rotation - values.sliceWidth/2),
                            endAngle: .degrees(values.rotation + values.sliceWidth/2)
                        )
                    )
                } else {
                    Color.clear
                }
            }
        }
    }
}

#Preview {
    GradientTest(
        rotationDuration: 4,
        pauseDuration: 0,
        maxSliceWidth: 90,
        convergenceAngle: 0
    )
}
