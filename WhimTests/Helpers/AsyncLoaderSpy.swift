//
//  AsyncLoaderSpy.swift
//  WhimTests
//
//  Created by Marija Zdravic on 30.04.2026..
//

import Foundation
import Testing

@MainActor
final class AsyncLoaderSpy<Param, Output: Sendable> {
    enum ResultState: Equatable {
        case success
        case failure
        case cancelled
    }

    struct Request {
        let param: Param
        fileprivate(set) var result: ResultState?
    }

    private(set) var requests = [Request]()
    private var continuations = [AsyncThrowingStream<Output, Error>.Continuation?]()
    private var requestWaiters = [(index: Int, continuation: CheckedContinuation<Void, Never>)]()

    func load(_ param: Param) async throws -> Output {
        let requestIndex = requests.count

        let (stream, continuation) = AsyncThrowingStream<Output, Error>.makeStream()
        requests.append(Request(param: param, result: nil))
        continuations.append(continuation)
        completeRequestWaiters()

        do {
            for try await output in stream {
                try Task.checkCancellation()
                return output
            }

            if Task.isCancelled {
                requests[requestIndex].result = .cancelled
                throw CancellationError()
            }

            requests[requestIndex].result = .failure
            throw NoOutput()
        } catch {
            requests[requestIndex].result = (Task.isCancelled || error is CancellationError) ? .cancelled : .failure
            throw error
        }
    }

    func waitForRequest(at index: Int = 0) async {
        guard requests.count <= index else { return }

        await withCheckedContinuation { continuation in
            requestWaiters.append((index, continuation))
        }
    }

    func completeRequest(with output: Output, at index: Int = 0) {
        guard continuations.indices.contains(index) else {
            Issue.record("No pending request at index \(index).")
            return
        }

        guard let continuation = continuations[index] else {
            Issue.record("Attempted to complete request at index \(index) more than once.")
            return
        }

        requests[index].result = .success
        continuation.yield(output)
        continuation.finish()
        continuations[index] = nil
    }

    func failRequest(with error: Error = anyNSError(), at index: Int = 0) {
        guard continuations.indices.contains(index) else {
            Issue.record("No pending request at index \(index).")
            return
        }

        guard let continuation = continuations[index] else {
            Issue.record("Attempted to fail request at index \(index) more than once.")
            return
        }

        if error is CancellationError {
            requests[index].result = .cancelled
        } else {
            requests[index].result = .failure
        }
        continuation.finish(throwing: error)
        continuations[index] = nil
    }

    private func completeRequestWaiters() {
        let ready = requestWaiters.filter { requests.count > $0.index }
        requestWaiters.removeAll { requests.count > $0.index }
        ready.forEach { $0.continuation.resume() }
    }
}

private extension AsyncLoaderSpy {
    struct NoOutput: Error {}
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
