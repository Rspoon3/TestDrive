//
//  Mine.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct Mine: View {
    @State private var isMoving = false
    @State private var boarderOpacity: CGFloat = 0
    @State private var boarderAngle: CGFloat = 90
    private let cornerRadius: CGFloat = 8
    
    var body: some View {
        Button("Get Started") {
        }
        .padding(16)
        .background(Color.white)
        .foregroundStyle(.purple)
        .cornerRadius(cornerRadius)
        .animatedBorder(
            rotationDuration: 20,
            pauseDuration: 2,
            maxSliceWidth: 90,
            convergenceProgress: 0,
            gradientColors: [.white, .purple],
            opacityAnimationPercentage: 0.1,
            cornerRadius: cornerRadius,
            lineWidth: 3
        )
        .padding(24)
        .background(Color.purple)
    }
}

#Preview {
    Mine()
}
