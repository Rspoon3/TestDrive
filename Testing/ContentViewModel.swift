import Foundation
import Combine

final class ContentViewModel: ObservableObject {
    @Published var value: Int = 0
    @Published var multiValue: Int = 0
    @Published var multiBool: Bool = true

    private var cancellables = Set<AnyCancellable>()

    let store: IntStore
    let multiStore: MultiDataStore

    init(
        store: IntStore = .shared,
        multiStore: MultiDataStore = .shared
    ) {
        self.store = store
        self.multiStore = multiStore

        // Observe IntStore
        store.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.value = newValue
            }
            .store(in: &cancellables)

        multiStore.publisher
            .map { ($0.int, $0.bool) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] int, bool in
                self?.multiValue = int
                self?.multiBool = bool
            }
            .store(in: &cancellables)
    }

    func updateValue(to newValue: Int) {
        store.value = newValue
    }

    func incrementIntStore() {
        store.value += 1
    }

    func decrementIntStore() {
        store.value -= 1
    }

    func incrementMulti() {
        multiStore.int += 1
    }

    func decrementMulti() {
        multiStore.int -= 1
    }
}
