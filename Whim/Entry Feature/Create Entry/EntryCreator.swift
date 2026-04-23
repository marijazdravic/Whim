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

    private let store: EntryStore
    private let idGenerator: () -> UUID
    private let dateGenerator: () -> Date

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
        let entry = Entry(
            id: idGenerator(),
            text: input.text,
            imageURL: input.imageURL,
            audioURL: input.audioURL,
            createdAt: dateGenerator()
        )

        do {
            try entry.validate()
        } catch Entry.ValidationError.missingContent {
            throw EntryCreator.Error.invalidInput
        }

        try store.insert(entry)
    }
}
