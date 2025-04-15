//
//  PlusCircleButton.swift
//  Workouts
//
//  Created by Richard Witherspoon on 11/22/22.
//

import SwiftUI
import SFSymbols

struct PlusCircleButton: View {
    let accessibilityTitle: String
    let color: Color
    let action: ()->Void
    
    init(
        accessibilityTitle: String,
        color: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.accessibilityTitle = accessibilityTitle
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(symbol: .plusCircleFill)
                .resizable()
                .frame(width: 44, height: 44)
                .padding([.trailing, .bottom])
                .foregroundStyle(.white, color)
        }
        .accessibilityLabel(accessibilityTitle)
    }
}

#Preview {
    PlusCircleButton(
        accessibilityTitle: "test",
        color: .blue
    ) {
    }
}
