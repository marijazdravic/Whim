//
//  WhimTests.swift
//  SaveEntryUseCaseTests
//
//  Created by Marija Zdravic on 07.04.2026..
//

import Testing
import Whim

public struct Entry {
    public let text: String
}

protocol EntryStore {}

class LocalEntrySaver{
    init(store: EntryStore) {}
}

struct SaveEntryUseCaseTests {
    @Test
    func init_doesNotRequestSave() {
        let store = EntryStoreSpy()
        _ = LocalEntrySaver(store: store)
        #expect(store.savedEntries.isEmpty)
    }
    
    private final class EntryStoreSpy: EntryStore {
        private(set) var savedEntries: [Entry] = []
        
        func save(_ entry: Entry) {
            savedEntries.append(entry)
        }
    }
}


