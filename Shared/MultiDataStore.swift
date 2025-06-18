//
//  MultiDataStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import Foundation
import Combine

final class MultiDataStore {
    static let shared = MultiDataStore()
    
    private let store = InMemoryStore<MultiData>(
        initialValue: MultiData(int: 0, string: "", bool: false)
    )
    
    private init() {}

    // MARK: - Combined Access

    var publisher: AnyPublisher<MultiData, Never> {
        store.publisher
    }

    // MARK: - Individual Accessors

    var int: Int {
        get { store.value.int }
        set {
            var copy = store.value
            copy.int = newValue
            store.value = copy
        }
    }

    var string: String {
        get { store.value.string }
        set {
            var copy = store.value
            copy.string = newValue
            store.value = copy
        }
    }

    var bool: Bool {
        get { store.value.bool }
        set {
            var copy = store.value
            copy.bool = newValue
            store.value = copy
        }
    }
}
