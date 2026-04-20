//
//  EntryStoreSpy.swift
//  WhimTests
//
//  Created by Marija Zdravic on 19.04.2026..
//

import Foundation
import Whim

final class EntryStoreSpy: EntryStore {

    enum ReceivedMessage: Equatable {
        case insert(Entry)
        case retrieve(UUID)
    }

    private(set) var receivedMessages = [ReceivedMessage]()
    private var insertionResult: Result<Void, Error>?

    var insertedEntry: Entry? {
        guard case let .insert(entry)? = receivedMessages.first else { return nil }
        return entry
    }

    func insert(_ entry: Entry) throws {
        receivedMessages.append(.insert(entry))
        try insertionResult?.get()
    }

    func retrieve(by id: UUID) throws -> Entry? {
        receivedMessages.append(.retrieve(id))
        return nil
    }

    func stubInsertionToFail(_ error: Swift.Error) {
        self.insertionResult = .failure(error)
    }
}

