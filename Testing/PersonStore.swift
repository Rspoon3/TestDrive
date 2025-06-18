//
//  PersonStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import Foundation
import Combine

final class PersonStore {
    static let shared = PersonStore()

    private let store = InMemoryStore<[Person]>(initialValue: [])

    private init() {}

    var people: [Person] {
        get { store.value }
        set { store.value = newValue }
    }

    var publisher: AnyPublisher<[Person], Never> {
        store.publisher
    }

    func add(_ person: Person) {
        store.value.append(person)
    }

    func remove(id: UUID) {
        store.value.removeAll { $0.id == id }
    }

    func update(_ person: Person) {
        store.value = store.value.map {
            $0.id == person.id ? person : $0
        }
    }
}