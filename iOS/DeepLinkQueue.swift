//
//  DeepLinkQueue.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DeepLinkQueue: ObservableObject {
    static let shared = DeepLinkQueue()
    
    @Published private(set) var queue: [DeepLink] = []
    private let deepLinkSubject = PassthroughSubject<DeepLink, Never>()
    private var isInitialized = false
    private var pendingColdStartLinks: [URL] = []
    private var isProcessingItem = false
    
    var queueCount: Int {
        queue.count
    }
    
    var deepLinkPublisher: AnyPublisher<DeepLink, Never> {
        deepLinkSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    func initialize() {
        isInitialized = true
        
        // Process any cold start deep links that were queued before initialization
        for url in pendingColdStartLinks {
            enqueue(url: url)
        }
        pendingColdStartLinks.removeAll()
        
        // Start emitting queued deep links
        processQueue()
    }
    
    func enqueue(url: URL) {
        let deepLink = DeepLink(url: url)
        
        // If not initialized yet (cold start), store for later processing
        guard isInitialized else {
            pendingColdStartLinks.append(url)
            return
        }
        
        print("🔗 Enqueuing deep link: \(url.absoluteString)")
        queue.append(deepLink)
        
        // Only start processing if we're not already processing an item
        if !isProcessingItem {
            processQueue()
        }
    }
    
    private func processQueue() {
        guard !queue.isEmpty, !isProcessingItem else { return }
        
        isProcessingItem = true
        let deepLink = queue.removeFirst()
        print("📤 Emitting deep link from queue: \(deepLink.url.absoluteString)")
        
        // Emit the deep link for processing immediately
        deepLinkSubject.send(deepLink)
    }
    
    func markProcessingComplete() {
        isProcessingItem = false
        
        // Continue processing the next item in queue if any
        processQueue()
    }
}