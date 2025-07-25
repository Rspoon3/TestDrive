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
        ZStack {
            
            Button("Get Started") {
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(8)
            .foregroundStyle(.purple)
        }
        .padding(24)
        .background(Color.purple)
        .cornerRadius(cornerRadius)
        .overlay {
            GradientTest()
                .rotationEffect(.degrees(-90))
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 3)) // inside stroke
                )
        }
    }
}

#Preview {
    Mine()
}
