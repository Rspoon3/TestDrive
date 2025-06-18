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
    
    // Convenience accessors
     var int: Int {
         get { store[\.int] }
         set { store[\.int] = newValue }
     }

     var string: String {
         get { store[\.string] }
         set { store[\.string] = newValue }
     }

     var bool: Bool {
         get { store[\.bool] }
         set { store[\.bool] = newValue }
     }
}
