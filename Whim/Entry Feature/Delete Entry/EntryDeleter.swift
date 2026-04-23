//
//  EntryDeleter.swift
//  Whim
//
//  Created by Marija Zdravic on 22.04.2026..
//

import Foundation

public final class EntryDeleter {
    private let store: EntryStore

    public init(store: EntryStore) {
        self.store = store
    }

    public func delete(by id: UUID) throws {
        try store.delete(by: id)
    }
}
