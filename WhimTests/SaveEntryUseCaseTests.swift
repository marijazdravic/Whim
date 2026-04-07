//
//  WhimTests.swift
//  SaveEntryUseCaseTests
//
//  Created by Marija Zdravic on 07.04.2026..
//

import Testing
import Whim

struct Entry: Equatable {
    public let text: String
}

struct CreateEntryInput: Equatable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

protocol EntryStore {
    func save(_ entry: Entry)
}

class LocalEntrySaver{
    let store: EntryStore
    
    init(store: EntryStore) {
        self.store = store
    }
    
    func save(_ input: CreateEntryInput) {
        let entry = Entry(text: input.text)
        store.save(entry)
    }
}

struct SaveEntryUseCaseTests {
    @Test
    func init_doesNotRequestSave() {
        let store = EntryStoreSpy()
        _ = LocalEntrySaver(store: store)
        #expect(store.receivedMessages.isEmpty)
    }
    
    @Test
    func save_requestsStoreToSaveEntryOnTextOnlyInput() {
        let store = EntryStoreSpy()
        let sut = LocalEntrySaver(store: store)
        sut.save(CreateEntryInput(text: "Hello"))
        #expect(store.receivedMessages == [.save(Entry(text: "Hello"))])
    }
    
    private final class EntryStoreSpy: EntryStore {
        enum Message: Equatable {
            case save(Entry)
        }
        
        private(set) var receivedMessages = [Message]()
        
        func save(_ entry: Entry) {
            receivedMessages.append(.save(entry))
        }
    }
}


