import Foundation

struct SpinAndWinData {
    var spinCount: Int
}

final class SpinAndWinStore: ThreadSafeStore<SpinAndWinData> {
    static let shared = SpinAndWinStore()
    
    private init() {
        super.init(initialValue: SpinAndWinData(spinCount: 0))
    }
    
    func incrementSpin() {
        queue.sync(flags: .barrier) {
            value.spinCount += 1
        }
    }
    
    func resetSpins() {
        setValue(SpinAndWinData(spinCount: 0))
    }
    
    var spinCount: Int {
        return queue.sync { value.spinCount }
    }
}