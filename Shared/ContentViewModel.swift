import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    @Published var value: Int = 0
    private var cancellables = Set<AnyCancellable>()
    let store: IntStore
    
    init(store: IntStore = .shared) {
        self.store = store
        store.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.value = newValue
            }
            .store(in: &cancellables)
    }
    
    func updateValue(to newValue: Int) {
        IntStore.shared.value = newValue
    }
}
