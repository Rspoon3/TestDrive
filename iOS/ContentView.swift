//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @Binding var deepLinkURL: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("TestDrive Deep Link Handler")
                .font(.title)
                .padding()
            
            if let url = deepLinkURL {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Received Deep Link:")
                        .font(.headline)
                    
                    Text(url.absoluteString)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    if let scheme = url.scheme {
                        Text("Scheme: \(scheme)")
                            .foregroundColor(.blue)
                    }
                    
                    if let host = url.host {
                        Text("Host: \(host)")
                            .foregroundColor(.blue)
                    }
                    
                    if !url.pathComponents.filter({ $0 != "/" }).isEmpty {
                        Text("Path: \(url.path)")
                            .foregroundColor(.blue)
                    }
                    
                    if let query = url.query {
                        Text("Query: \(query)")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            } else {
                Text("No deep link received yet")
                    .foregroundColor(.gray)
                
                Text("Try opening a testdrive:// URL")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(deepLinkURL: .constant(nil))
}
