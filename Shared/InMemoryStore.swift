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
}
