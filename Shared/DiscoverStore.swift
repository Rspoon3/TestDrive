import Foundation

struct DiscoverData {
    var itemCount: Int
    var isDiscovering: Bool
    var currentLocation: String
    var lastDiscoveredItem: String
}

final class DiscoverStore: ThreadSafeStore<DiscoverData> {
    static let shared = DiscoverStore()
    
    private init() {
        super.init(initialValue: DiscoverData(
            itemCount: 0,
            isDiscovering: false,
            currentLocation: "",
            lastDiscoveredItem: ""
        ))
    }
    
    func startDiscovering(at location: String) {
        queue.sync(flags: .barrier) {
            value.isDiscovering = true
            value.currentLocation = location
        }
    }
    
    func stopDiscovering() {
        queue.sync(flags: .barrier) {
            value.isDiscovering = false
            value.currentLocation = ""
        }
    }
    
    func discoverItem(_ item: String) {
        queue.sync(flags: .barrier) {
            value.itemCount += 1
            value.lastDiscoveredItem = item
        }
    }
    
    func resetDiscovery() {
        setValue(DiscoverData(
            itemCount: 0,
            isDiscovering: false,
            currentLocation: "",
            lastDiscoveredItem: ""
        ))
    }
    
    var itemCount: Int {
        return queue.sync { value.itemCount }
    }
    
    var isDiscovering: Bool {
        return queue.sync { value.isDiscovering }
    }
    
    var currentLocation: String {
        return queue.sync { value.currentLocation }
    }
    
    var lastDiscoveredItem: String {
        return queue.sync { value.lastDiscoveredItem }
    }
}