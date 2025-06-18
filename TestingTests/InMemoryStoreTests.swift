//
//  InMemoryStoreTests.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import XCTest
@testable import Testing

final class InMemoryStoreTests: XCTestCase {

    // MARK: - Basic Functionality Tests
    
    func testBasicValueAccess() {
        let store = InMemoryStore<Int>(initialValue: 42)
        XCTAssertEqual(store.value, 42)
        
        store.value = 100
        XCTAssertEqual(store.value, 100)
    }
    
    func testMutateBasicOperation() {
        let store = InMemoryStore<Int>(initialValue: 10)
        
        store.mutate { $0 += 5 }
        XCTAssertEqual(store.value, 15)
        
        store.mutate { $0 *= 2 }
        XCTAssertEqual(store.value, 30)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentWritesWithDirectAssignmentFails() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let iterations = 1_000
        let expectation = XCTestExpectation(description: "Concurrent increments complete")

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: iterations) { _ in
                store.value += 1
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)

        // This test is expected to fail due to race conditions
        // The actual value will be less than expected iterations
        XCTAssertLessThan(store.value, iterations, "Direct assignment should lose increments due to race conditions")
    }

    func testConcurrentReadsAndWritesWithDirectAssignmentFails() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let readQueue = DispatchQueue(label: "read", attributes: .concurrent)
        let writeQueue = DispatchQueue(label: "write", attributes: .concurrent)

        let group = DispatchGroup()
        let writeIterations = 1_000  // Reduced for faster test
        let readIterations = 1_000

        for _ in 0..<writeIterations {
            group.enter()
            writeQueue.async {
                store.value += 1  // Race condition
                group.leave()
            }
        }

        for _ in 0..<readIterations {
            group.enter()
            readQueue.async {
                _ = store.value
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 5)
        XCTAssertEqual(result, .success, "Concurrent read/write tasks should complete")

        // This should fail due to race conditions
        XCTAssertLessThan(store.value, writeIterations, "Direct assignment should lose increments due to race conditions")
    }
    
    // MARK: - Thread Safety Tests (Working - using mutate)
    
    func testConcurrentWritesWithMutateAreThreadSafe() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let iterations = 10_000
        let expectation = XCTestExpectation(description: "Concurrent mutate increments complete")

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: iterations) { _ in
                store.mutate { $0 += 1 }  // Atomic operation
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(store.value, iterations, "Mutate should be thread-safe and not lose increments")
    }

    func testConcurrentReadsAndWritesWithMutateAreThreadSafe() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let readQueue = DispatchQueue(label: "read", attributes: .concurrent)
        let writeQueue = DispatchQueue(label: "write", attributes: .concurrent)

        let group = DispatchGroup()
        let writeIterations = 5_000
        let readIterations = 5_000

        for _ in 0..<writeIterations {
            group.enter()
            writeQueue.async {
                store.mutate { $0 += 1 }  // Atomic operation
                group.leave()
            }
        }

        for _ in 0..<readIterations {
            group.enter()
            readQueue.async {
                _ = store.value
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 5)
        XCTAssertEqual(result, .success, "Concurrent read/write tasks should complete")

        XCTAssertEqual(store.value, writeIterations, "Mutate should be thread-safe and account for all writes")
    }
    
    // MARK: - Complex Mutate Operations
    
    func testComplexMutateOperations() {
        let store = InMemoryStore<String>(initialValue: "Hello")
        
        store.mutate { value in
            value += " World"
            value = value.uppercased()
        }
        
        XCTAssertEqual(store.value, "HELLO WORLD")
    }
    
    func testMutateWithStructs() {
        struct Counter {
            var count: Int
            var name: String
        }
        
        let store = InMemoryStore<Counter>(initialValue: Counter(count: 0, name: "Test"))
        
        store.mutate { counter in
            counter.count += 10
            counter.name = "Updated"
        }
        
        XCTAssertEqual(store.value.count, 10)
        XCTAssertEqual(store.value.name, "Updated")
    }
    
    // MARK: - Publisher Tests
    
    func testPublisherEmitsChanges() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let expectation = XCTestExpectation(description: "Publisher emits changes")
        var receivedValues: [Int] = []
        
        let cancellable = store.publisher
            .sink { value in
                receivedValues.append(value)
                if receivedValues.count == 3 {
                    expectation.fulfill()
                }
            }
        
        store.value = 1
        store.mutate { $0 = 2 }
        
        wait(for: [expectation], timeout: 1)
        
        XCTAssertEqual(receivedValues, [0, 1, 2])
        cancellable.cancel()
    }
}
