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
    private let sequentialSubject = CurrentValueSubject<DeepLink?, Never>(nil) // Sequential emissions
    private let immediateSubject = CurrentValueSubject<DeepLink?, Never>(nil) // Immediate emissions
    
    var queueCount: Int {
        queue.filter { $0.status == .queued }.count
    }
    
    private var isProcessing: Bool {
        queue.contains { $0.status == .processing }
    }
    
    var sequentialPublisher: AnyPublisher<DeepLink, Never> {
        sequentialSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    var immediatePublisher: AnyPublisher<DeepLink, Never> {
        immediateSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    private init() {}
    
    // MARK: - Public
    
    func enqueue(url: URL) {
        let deepLink = DeepLink(url: url)
        
        print("🔗 Enqueuing deep link: \(url.absoluteString)")
        queue.append(deepLink)
        
        // Emit immediately for consumers that need instant processing
        immediateSubject.send(deepLink)
        
        // Only start sequential processing if we're not already processing an item
        guard !isProcessing else { return }
        processQueue()
    }
    
    func markProcessingComplete(id: UUID) {
        // Remove the specific item by ID
        queue.removeAll { $0.id == id }
        
        // Continue processing the next item in queue if any
        processQueue()
    }
    
    // MARK: - Private
    
    private func processQueue() {
        // Find first queued item
        guard let index = queue.firstIndex(where: { $0.status == .queued }) else { return }
        guard !isProcessing else { return }
        
        // Mark as processing
        queue[index].status = .processing
        let deepLink = queue[index]
        print("📤 Emitting deep link from queue: \(deepLink.url.absoluteString)")
        
        // Emit the deep link for processing
        sequentialSubject.send(deepLink)
    }
}
