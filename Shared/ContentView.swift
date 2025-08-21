import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Clock Faces") {
                    NavigationLink(destination: RectangularClockView()) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Rectangular Path Clock")
                                    .font(.headline)
                                Text("Balls travel along a rounded rectangle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: PhysicsBallClockView()) {
                        HStack {
                            Image(systemName: "circles.hexagonpath")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Physics Ball Clock")
                                    .font(.headline)
                                Text("Balls drop and respond to device motion")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Features") {
                    Label("Hours in orange", systemImage: "circle.fill")
                        .foregroundColor(.orange)
                    Label("Minutes in blue", systemImage: "circle.fill")
                        .foregroundColor(.blue)
                    Label("Seconds in green", systemImage: "circle.fill")
                        .foregroundColor(.green)
                }
                .font(.footnote)
            }
            .navigationTitle("Watch Faces")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
}