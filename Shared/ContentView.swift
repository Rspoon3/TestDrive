import SwiftUI
import FamilyControls

struct ContentView: View {
    @StateObject var model = AppModel.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let summary = model.activitySummary {
                    ActivityRingViewRepresentable(summary: summary)
                        .frame(width: 150, height: 150)
                }
                
                FamilyActivityPicker(selection: $model.selection)
                    .frame(height: 300)
                
                Button("Check Rings & Steps Now") {
                    Task {
                        try await model.requestHealthKitAuthorization()
                    }
                }
                
                Button("Unblock") {
                    model.unblockAll()
                }
            }
            .navigationTitle("Ring-Rewards")
            .padding()
            .buttonStyle(.borderedProminent)
            .onAppear {
                Task {
                    try await model.requestHealthKitAuthorization()
                }
            }
        }
    }
}
