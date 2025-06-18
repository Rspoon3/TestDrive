//
//  InMemoryStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//

import Foundation
import Combine
import os.lock

final class InMemoryStore<T> {
    private let lock = OSAllocatedUnfairLock()
    private var _value: T
    private let subject: CurrentValueSubject<T, Never>
    
    init(initialValue: T) {
        self._value = initialValue
        self.subject = CurrentValueSubject(initialValue)
    }
    
    var value: T {
        get {
            lock.withLock {
                _value
            }
        }
        set {
            lock.withLock {
                _value = newValue
                subject.send(newValue)
            }
        }
    }
    
    var publisher: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
    
    subscript<Value>(keyPath: WritableKeyPath<T, Value>) -> Value {
        get {
            value[keyPath: keyPath]
        }
        set {
            value = {
                var copy = $0
                copy[keyPath: keyPath] = newValue
                return copy
            }(value)
        }
    }
    
    /// Performs an atomic read-modify-write operation
    /// Use this for compound operations like +=, -=, etc. to ensure atomicity
    func mutate(_ transform: (inout T) -> Void) {
        lock.withLock {
            transform(&_value)
            subject.send(_value)
        }
    }
}
