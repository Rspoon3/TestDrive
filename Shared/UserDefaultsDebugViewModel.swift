//
//  UserDefaultsDebugViewModel.swift
//  TestDrive
//
//  Created by Assistant on 8/26/25.
//

import SwiftUI
import Combine

final class UserDefaultsDebugViewModel: ObservableObject {
    @Published var userDefaultsItems: [(key: String, value: Any)] = []
    @Published var searchText: String = ""
    @Published var editableValues: [String: Any] = [:]
    @Published var pinnedKeys: Set<String> = []
    
    private let pinnedKeysStorageKey = "__UserDefaultsDebugView_pinnedKeys"
    
    var filteredItems: [(key: String, value: Any)] {
        // Use editableValues to show current edited values, not original values
        let items = userDefaultsItems.map { item in
            let editedValue = editableValues[item.key]
            let finalValue = editedValue ?? item.value
            return (key: item.key, value: finalValue)
        }
        
        let filtered = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? items
            : items.filter { 
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                String(describing: $0.value).localizedCaseInsensitiveContains(searchText)
            }
        let result = filtered.sorted { $0.key < $1.key }
        return result
    }
    
    var pinnedItems: [(key: String, value: Any)] {
        filteredItems.filter { pinnedKeys.contains($0.key) }
    }
    
    var unpinnedItems: [(key: String, value: Any)] {
        filteredItems.filter { !pinnedKeys.contains($0.key) }
    }
    
    init() {
        loadUserDefaults()
        loadPinnedKeys()
    }
    
    func loadUserDefaults() {
        let userDefaults = UserDefaults.standard
        userDefaultsItems = userDefaults.dictionaryRepresentation()
            .filter { !$0.key.hasPrefix("__UserDefaultsDebugView_") }
            .map { ($0.key, $0.value) }
        
        editableValues = userDefaultsItems.reduce(into: [:]) { result, item in
            result[item.key] = item.value
        }
    }
    
    func loadPinnedKeys() {
        if let savedPins = UserDefaults.standard.array(forKey: pinnedKeysStorageKey) as? [String] {
            pinnedKeys = Set(savedPins)
        }
    }
    
    func savePinnedKeys() {
        UserDefaults.standard.set(Array(pinnedKeys), forKey: pinnedKeysStorageKey)
    }
    
    func updateValue(_ newValue: Any, forKey key: String) {
        // Save to editableValues
        let oldEditableValue = editableValues[key]
        editableValues[key] = newValue
        
        // Save to UserDefaults
        UserDefaults.standard.set(newValue, forKey: key)
        
        // Verify it was saved
        let savedValue = UserDefaults.standard.object(forKey: key)
        
        // Update the specific item in userDefaultsItems to trigger UI update
        if let index = userDefaultsItems.firstIndex(where: { $0.key == key }) {
            let oldValue = userDefaultsItems[index].value
            userDefaultsItems[index] = (key: key, value: newValue)
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    func deleteItem(withKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        pinnedKeys.remove(key)
        savePinnedKeys()
        loadUserDefaults()
    }
    
    func togglePin(forKey key: String) {
        withAnimation {
            if pinnedKeys.contains(key) {
                pinnedKeys.remove(key)
            } else {
                pinnedKeys.insert(key)
            }
            savePinnedKeys()
        }
    }
    
    func isPinned(key: String) -> Bool {
        pinnedKeys.contains(key)
    }
}
