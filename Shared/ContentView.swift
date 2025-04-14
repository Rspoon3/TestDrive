import SwiftUI
import FamilyControls
import DeviceActivity

struct ContentView: View {
    @StateObject var model = AppModel.shared

    var body: some View {    
        DeviceActivityReport(.home)
    }

    var body1: some View {
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

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let home = Self("Home Report")
    static let widget = Self("Widget")
    static let moreInsights = Self("More Insights")
}
