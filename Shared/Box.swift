//
//  Box.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/2/25.
//

import SwiftUI

struct Box: View {
    @State var fullScreen = false
    @State var scale: CGFloat = 1
    @State var offset: CGFloat = 0
    @State var boxWidth: CGFloat = 28
    @State var boxOpacity: CGFloat = 1

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(.purple)
                .frame(width: fullScreen ? 200 : 56)
            
                .overlay {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 4))
                        .foregroundStyle(.red)
                }
                .scaleEffect(scale)
                .overlay {
                    Image("spinAndWinBox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: boxWidth)
                        .scaleEffect(fullScreen ? 4 : 1)
                        .offset(y: offset)
                        .opacity(boxOpacity)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: fullScreen ? .center : .bottomTrailing
                )
            
            Button("Toggle") {
                Task {
                    withAnimation(.linear(duration: 0.3)) {
                        fullScreen.toggle()
                    }
                    
                    try await Task.sleep(for: .seconds(0.6))
                    
                    withAnimation(.linear(duration: 0.3)) {
                        scale = 5
                    }
                    
                    try await Task.sleep(for: .seconds(0.6))
                    
                    withAnimation(.linear(duration: 0.2)) {
                        boxWidth = 50
                        offset = -100
                        boxOpacity = 0
                    }
                }
            }
        }
    }
}

#Preview {
    Box()
}
