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
        case update(Entry)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    private var insertionResult: Result<Void, Error>?
    private var retrievalResult: Result<Entry?, Error>?
    private var updateResult: Result<Void, Error>?
    
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
        return try retrievalResult?.get()
    }
    
    func update(_ entry: Entry) throws {
        receivedMessages.append(.update(entry))
        try updateResult?.get()
    }
    
    
    func stubInsertion(with error: Swift.Error) {
        insertionResult = .failure(error)
    }

    func stubRetrieval(with entry: Entry) {
        retrievalResult = .success(entry)
    }

    func stubUpdate(with error: Swift.Error) {
        updateResult = .failure(error)
    }
}

