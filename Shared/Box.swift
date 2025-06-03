//
//  Box.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/2/25.
//

import SwiftUI
import Combine

final class BoxViewModel: ObservableObject {
    @Published var fullScreen = false
    @Published var scale: CGFloat = 1
    @Published var offset: CGFloat = 0
    @Published var boxWidth: CGFloat = 28
    @Published var boxOpacity: CGFloat = 1
    let cornerRadius: CGFloat = 22
    let height: CGFloat = 56
    let extraTime: CGFloat = 1
    
    func start() async throws {
        withAnimation(.linear(duration: extraTime + 0.3)) {
            fullScreen.toggle()
        }
        
        try await Task.sleep(for: .seconds(extraTime + 0.6))
        
        withAnimation(.linear(duration: extraTime + 0.3)) {
            scale = 5
        }
        
        try await Task.sleep(for: .seconds(extraTime + 0.6))
        
        withAnimation(.linear(duration: extraTime + 0.2)) {
            boxWidth = 50
            offset = -100
            boxOpacity = 0
        }
    }
}

struct Box: View {
    @ObservedObject var viewModel: BoxViewModel
    
    var body: some View {
        RoundedRectangle(cornerRadius: viewModel.fullScreen ? 100 : viewModel.cornerRadius)
            .foregroundStyle(Color.darkPurple)
            .frame(
                width: viewModel.fullScreen ? 200 : viewModel.height,
                height: viewModel.fullScreen ? 200 : viewModel.height
            )
            .overlay {
                RoundedRectangle(cornerRadius: viewModel.fullScreen ? 100 : viewModel.cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3))
                    .foregroundStyle(.purple)
            }
            .scaleEffect(viewModel.scale)
            .overlay {
                Image("spinAndWinBox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewModel.boxWidth)
                    .scaleEffect(viewModel.fullScreen ? 4 : 1)
                    .offset(y: viewModel.offset)
                    .opacity(viewModel.boxOpacity)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: viewModel.fullScreen ? .center : .bottomTrailing
            )
            .task {
//                try? await Task.sleep(for: .seconds(1))
                try? await viewModel.start()
            }
    }
}

#Preview {
    Box(viewModel: .init())
}
