import Foundation
import Combine

final class ThreadSafeIntegerStore: ObservableObject {
    @Published private(set) var value: Int = 0
    private let queue = DispatchQueue(label: "com.threadSafeIntegerStore.queue", attributes: .concurrent)
    
    func setValue(_ newValue: Int) {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.value = newValue
            }
        }
    }
    
    func increment() {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.value += 1
            }
        }
    }
    
    func decrement() {
        queue.async(flags: .barrier) {
            DispatchQueue.main.async {
                self.value -= 1
            }
        }
    }
}