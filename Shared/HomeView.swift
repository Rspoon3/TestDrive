//
//  HomeView.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/14/25.
//

import SwiftUI
import SwiftTools

struct HomeView: View {
    @State var totalStepsToday: Int = Int.random(in: 1...100)
    @State var mindfulMinutesToday: Int = Int.random(in: 1...100)
    @State var ringsClosed: Bool = Bool.random()
    @State var streakCount: Int = Int.random(in: 1...100)

    @State private var selectedBlockModes: Set<BlockMode> = [.steps, .mindfulness]
    @State private var skipOption: SkipOption = .five
    @Namespace private var skipAnimation
    
    @State private var blockStatus: [BlockMode: Bool] = [
        .steps: false,
        .rings: true,
        .mindfulness: false
    ]
    
    
    // Placeholder apps
    let mockApps: [String] = ["📱", "🎮", "📸", "📺", "🛍", "🎵", "💬", "📷"]
    let columns = [GridItem(.adaptive(minimum: 60))]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // 🔒 Blocked Apps Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Blocked Apps")
                        .font(.title.bold())
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mockApps, id: \.self) { emoji in
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    Text(emoji)
                                        .font(.largeTitle)
                                }
                                Text("App")
                                    .font(.caption)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                Image(symbol: .plus)
                                    .font(.largeTitle)
                            }
                            Text("Add")
                                .font(.caption)
                        }
                    }
                }

                // 🎛️ Blocking Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Blocking Conditions")
                        .font(.title.bold())

                    FlowLayout(alignment: .leading) {
                        ForEach(BlockMode.allCases, id: \.self) { mode in
                            VStack {
                                Button {
                                    toggleBlockMode(mode)
                                } label: {
                                    Label(mode.label, systemImage: mode.icon)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedBlockModes.contains(mode) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                
                                // Status text
                                if selectedBlockModes.contains(mode) {
                                    Text(blockStatus[mode] == true ? "✓ Completed" : "Not Yet")
                                        .font(.caption)
                                        .foregroundColor(blockStatus[mode] == true ? .green : .secondary)
                                } else {
                                    Text("Not Enabled")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                // 🕓 Skip Options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Skip Blocking")
                        .font(.title.bold())

                    FlowLayout(alignment: .leading) {
                        ForEach(SkipOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.bouncy) {
                                    skipOption = option
                                }
                            } label: {
                                ZStack {
                                    if skipOption == option {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.blue.opacity(0.2))
                                            .matchedGeometryEffect(id: "skipHighlight", in: skipAnimation)
                                    }

                                    Label(option.label, systemImage: option.icon)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .foregroundColor(.primary)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.clear)
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Today's Progress")
                        .font(.title.bold())

                    ProgressRow(title: "Steps", value: Double(10_000), goal: 10_000, systemImage: "figure.walk")
                    ProgressRow(title: "Mindfulness", value: Double(5), goal: 5, systemImage: "brain.head.profile")

                    HStack {
                        Label(ringsClosed ? "Rings Closed 🎉" : "Rings Not Yet 🔁", systemImage: "activity")
                            .foregroundColor(ringsClosed ? .green : .gray)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .sensoryFeedback(.selection, trigger: selectedBlockModes)
        .sensoryFeedback(.selection, trigger: skipOption)
        .navigationTitle("Earn It")
    }

    private func toggleBlockMode(_ mode: BlockMode) {
        withAnimation(.bouncy) {
            if selectedBlockModes.contains(mode) {
                guard selectedBlockModes.count > 1 else { return }
                selectedBlockModes.remove(mode)
            } else {
                selectedBlockModes.insert(mode)
            }
        }
    }
}


#Preview {
    NavigationStack {
        HomeView()
            .navigationTitle("Home")
    }
}
