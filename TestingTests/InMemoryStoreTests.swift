//
//  InMemoryStoreTests.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import XCTest
@testable import Testing

final class InMemoryStoreTests: XCTestCase {

    func testConcurrentWritesAreThreadSafe() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let iterations = 10_000
        let expectation = XCTestExpectation(description: "Concurrent increments complete")

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.concurrentPerform(iterations: iterations) { _ in
                store.value += 1
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(store.value, iterations, "Final value should equal total increments")
    }

    func testConcurrentReadsAndWrites() {
        let store = InMemoryStore<Int>(initialValue: 0)
        let readQueue = DispatchQueue(label: "read", attributes: .concurrent)
        let writeQueue = DispatchQueue(label: "write", attributes: .concurrent)

        let group = DispatchGroup()
        let writeIterations = 5_000
        let readIterations = 5_000

        for _ in 0..<writeIterations {
            group.enter()
            writeQueue.async {
                store.value += 1
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

        XCTAssertEqual(store.value, writeIterations, "All writes should be accounted for")
    }
}
