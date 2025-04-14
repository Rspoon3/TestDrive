import SwiftUI
import ManagedSettings
import FamilyControls
import DeviceActivity

struct ContentView: View {
    @StateObject var model = AppModel.shared
    @State private var showPicker = false

    var body2: some View {
        DeviceActivityReport(.home)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if let summary = model.activitySummary {
                        ActivityRingViewRepresentable(summary: summary)
                            .frame(width: 150, height: 150)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "figure.walk")
                            Text("Steps: \(model.totalStepsToday.formatted()) / \(model.stepGoal.formatted())")
                        }

                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Mindful Minutes: \(model.mindfulMinutesToday.formatted()) / 5")
                        }
                    }
                    .padding(.top)
                    .font(.subheadline)
                    
                    HStack {
                        ForEach(Array(model.savedAppTokens), id: \.self) { token in
                            Label(token)
                                .labelStyle(.iconOnly)
                                .scaleEffect(1.75)
                        }
                    }
                    
                    Button("Check Rings & Steps Now") {
                        Task {
                            try await model.requestHealthKitAuthorization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Earn It!")
            .padding()
            .buttonStyle(.borderedProminent)
            .familyActivityPicker(
                isPresented: $showPicker,
                selection: $model.selection
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        showPicker.toggle()
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Unblock", role: .destructive) {
                        model.unblockAll()
                    }
                }
            }
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
