//
//  AsyncLoaderSpy.swift
//  WhimTests
//
//  Created by Marija Zdravic on 30.04.2026..
//

import Foundation

@MainActor
final class AsyncLoaderSpy<Param, Output: Sendable> {
    private(set) var requests = [Param]()
    private var continuations = [CheckedContinuation<Output, Error>?]()
    private var requestWaiters = [(index: Int, continuation: CheckedContinuation<Void, Never>)]()

    func load(_ param: Param) async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            requests.append(param)
            continuations.append(continuation)
            completeRequestWaiters()
        }
    }

    func waitForRequest(at index: Int = 0) async {
        guard requests.count <= index else { return }

        await withCheckedContinuation { continuation in
            requestWaiters.append((index, continuation))
        }
    }

    func completeRequest(with output: Output, at index: Int = 0) {
        guard let continuation = continuations[index] else { return }

        continuations[index] = nil
        continuation.resume(returning: output)
    }

    func failRequest(with error: Error = anyNSError(), at index: Int = 0) {
        guard let continuation = continuations[index] else { return }

        continuations[index] = nil
        continuation.resume(throwing: error)
    }

    private func completeRequestWaiters() {
        let ready = requestWaiters.filter { requests.count > $0.index }
        requestWaiters.removeAll { requests.count > $0.index }
        ready.forEach { $0.continuation.resume() }
    }
}

extension AsyncLoaderSpy where Param == Void {
    func load() async throws -> Output {
        try await load(())
    }
}

extension AsyncLoaderSpy where Output == Void {
    func completeRequest(at index: Int = 0) {
        completeRequest(with: (), at: index)
    }
}
