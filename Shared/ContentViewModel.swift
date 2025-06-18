import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    @Published var value: Int = 0
    
    let store: any IntegerStore
    private var timer: Timer?
    
    init(store: any IntegerStore = ThreadSafeIntegerStore.shared) {
        self.store = store
        self.value = store.value
        startPolling()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.value = self.store.value
            }
        }
    }
    
    func increment() {
        store.increment()
    }
    
    func decrement() {
        store.decrement()
    }
}
