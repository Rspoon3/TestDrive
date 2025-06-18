import Foundation
import Combine

protocol DataStore: AnyObject {
    associatedtype Value
    var value: Value { get }
    func setValue(_ newValue: Value)
}

protocol IntegerStore: DataStore where Value == Int {
    func increment()
    func decrement()
}

class ThreadSafeStore<T>: DataStore {
    typealias Value = T
    
    internal var value: T
    let queue = DispatchQueue(label: "com.threadSafeStore.queue", attributes: .concurrent)
    
    init(initialValue: T) {
        self.value = initialValue
    }
    
    func setValue(_ newValue: T) {
        queue.async(flags: .barrier) {
            self.value = newValue
        }
    }
}

final class ThreadSafeIntegerStore: ThreadSafeStore<Int>, IntegerStore {
    static let shared = ThreadSafeIntegerStore()
    
    private init() {
        super.init(initialValue: 0)
    }
    
    func increment() {
        queue.sync(flags: .barrier) {
            value += 1
        }
    }
    
    func decrement() {
        queue.sync(flags: .barrier) {
            value -= 1
        }
    }
}
