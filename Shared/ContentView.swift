//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var fileURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let riveURL = URL(string: "https://prod-static-content.fetchrewards.com/content-service/spin_cta_pointling_animation_92bed5ced2.riv")!
    private let fileStorage = try! FileStorage(
        directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("RiveAssets"),
        ttl: 6 * 60
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FileStorage Test")
                .font(.title)
                .padding()
            
            if isLoading {
                ProgressView("Downloading Rive file...")
            } else if let fileURL {
                VStack {
                    Text("✅ File downloaded successfully!")
                        .foregroundColor(.green)
                    Text("Local path: \(fileURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let errorMessage = errorMessage {
                Text("❌ Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Download Rive File") {
                Task {
                    await downloadFile()
                }
            }
            .disabled(isLoading)
            
            if fileURL != nil {
                Button("Clear Cache") {
                    Task {
                        await clearCache()
                    }
                }
            }
        }
        .padding()
    }
    
    private func downloadFile() async {
        isLoading = true
        errorMessage = nil
        fileURL = nil
        
        do {
            let localURL = try await fileStorage.fetchFile(from: riveURL)
            self.fileURL = localURL
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    private func clearCache() async {
        await fileStorage.clearExpiredFiles()
        self.fileURL = nil
    }
}

#Preview {
    ContentView()
}
