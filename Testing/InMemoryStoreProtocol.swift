//
//  InMemoryStoreProtocol.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/25/25.
//

import Foundation
import Combine

public protocol InMemoryStoreProtocol {
    associatedtype StoreValue
    
    /// The current value stored in the store
    var value: StoreValue { get set }
    
    /// Publisher that emits the current value whenever it changes
    var publisher: AnyPublisher<StoreValue, Never> { get }
    
    /// Performs an atomic read-modify-write operation
    func mutate(_ transform: (inout StoreValue) -> Void)
}

// MARK: - Async Protocol
protocol AsyncInMemoryStoreProtocol {
    associatedtype StoreValue
    
    /// The current value stored in the store
    var value: StoreValue { get set }
    
    /// Publisher that emits the current value whenever it changes
    var publisher: AnyPublisher<StoreValue, Never> { get }
    
    /// Gets a value at the specified keypath
    func get<Value>(_ keyPath: KeyPath<StoreValue, Value>) -> Value
    
    /// Sets a value at the specified keypath
    func set<Value>(_ keyPath: WritableKeyPath<StoreValue, Value>, to newValue: Value)
    
    /// Performs an atomic read-modify-write operation
    func mutate(_ transform: (inout StoreValue) -> Void)
}
