//
//  EntryCreator.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public final class EntryCreator {
    public enum Error: Swift.Error, Equatable {
        case invalidInput
    }

    let store: EntryStore

    let idGenerator: () -> UUID
    let dateGenerator: () -> Date

    public init(
        store: EntryStore,
        idGenerator: @escaping () -> UUID = UUID.init,
        dateGenerator: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.idGenerator = idGenerator
        self.dateGenerator = dateGenerator
    }

    public func createEntry(from input: CreateEntryInput) throws {
        guard hasContent(input) else {
            throw EntryCreator.Error.invalidInput
        }

        let entry = Entry(
            id: idGenerator(),
            text: input.text,
            createdAt: dateGenerator()
        )

        try store.insert(entry)
    }

    private func hasContent(_ input: CreateEntryInput) -> Bool {
        !input.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
