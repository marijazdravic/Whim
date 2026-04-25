//
//  EntryLoader.swift
//  Whim
//
//  Created by Marija Zdravic on 25.04.2026..
//

import Foundation

public final class EntryLoader {
    private let store: EntryStore

    public init(store: EntryStore) {
        self.store = store
    }

    public func load() throws -> [Entry] {
        try store
            .retrieveAll()
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    public func load(by id: UUID) throws -> Entry? {
        try store.retrieve(by: id)
    }
}
