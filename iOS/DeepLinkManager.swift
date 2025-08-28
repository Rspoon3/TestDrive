//
//  DeepLinkManager.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var isProcessing = false // Used for demo UI only
    @Published var currentDeepLink: DeepLink? // Used for demo UI only
    
    private var cancellables = Set<AnyCancellable>()
    private let queue = DeepLinkQueue.shared
    
    private init() {
        setupSubscription()
    }
    
    private func setupSubscription() {
        // Subscribe to deep links from the queue
        queue.deepLinkPublisher
            .sink { [weak self] deepLink in
                Task { @MainActor in
                    await self?.processDeepLink(deepLink)
                }
            }
            .store(in: &cancellables)
    }
    
    private func processDeepLink(_ deepLink: DeepLink) async {
        // Mark as processing
        isProcessing = true
        currentDeepLink = deepLink
        
        defer {
            // Mark as completed
            currentDeepLink = nil
            isProcessing = false
        }
        
        print("🚀 Processing deep link: \(deepLink.url.absoluteString)")
        
        // Simulate network call delay
        print("⏳ Simulating network call for: \(deepLink.url.absoluteString)")
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        print("✅ Network call completed, executing deep link action")
        
        // Execute the deep link action
        switch deepLink.action {
        case .navigateToColor(let color):
            NavigationCoordinator.shared.navigate(to: .colorScreen(color))
            
        case .presentColorSheet(let color):
            NavigationCoordinator.shared.presentSheet(.colorSheet(color))
            
        case .unknown:
            print("⚠️ Unknown deep link action: \(deepLink.url.absoluteString)")
        }
        
        // Notify queue that processing is complete
        queue.markProcessingComplete()
    }
}

struct DeepLink {
    let url: URL
    let action: DeepLinkAction
    let timestamp = Date()
    
    init(url: URL) {
        self.url = url
        self.action = DeepLinkAction.parse(from: url)
    }
}

enum DeepLinkAction {
    case navigateToColor(String)
    case presentColorSheet(String)
    case unknown
    
    static func parse(from url: URL) -> DeepLinkAction {
        guard url.scheme == "testdrive" else { return .unknown }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch url.host {
        case "color":
            if let colorName = pathComponents.first {
                if url.queryItems?.contains(where: { $0.name == "sheet" && $0.value == "true" }) == true {
                    return .presentColorSheet(colorName)
                } else {
                    return .navigateToColor(colorName)
                }
            }
        default:
            break
        }
        
        return .unknown
    }
}

extension URL {
    var queryItems: [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return components.queryItems
    }
}
