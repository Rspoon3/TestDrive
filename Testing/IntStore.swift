//
//  IntStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import Foundation
import Combine

final class IntStore {
    static let shared = IntStore()
    
    private let store = InMemoryStore<Int>(initialValue: 0)
    
    private init() {}
    
    var value: Int {
        get { store.value }
        set { store.value = newValue }
    }
    
    var publisher: AnyPublisher<Int, Never> {
        store.publisher
    }
}
