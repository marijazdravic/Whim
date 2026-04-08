//
//  WhimTests.swift
//  SaveEntryUseCaseTests
//
//  Created by Marija Zdravic on 07.04.2026..
//

import Foundation
import Testing
import Whim

struct Entry: Equatable {
    let id: UUID
    let text: String?
    let createdAt: Date
}

struct CreateEntryInput: Equatable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

protocol EntryStore {
    func save(_ entry: Entry) throws
}

class LocalEntrySaver {
    enum Error: Swift.Error, Equatable {
        case invalidInput
    }

    let store: EntryStore

    let idGenerator: () -> UUID
    let dateGenerator: () -> Date

    init(
        store: EntryStore,
        idGenerator: @escaping () -> UUID = UUID.init,
        dateGenerator: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.idGenerator = idGenerator
        self.dateGenerator = dateGenerator
    }

    func save(_ input: CreateEntryInput) throws {
        guard hasContent(input) else {
            throw LocalEntrySaver.Error.invalidInput
        }

        let entry = Entry(
            id: idGenerator(),
            text: input.text,
            createdAt: dateGenerator()
        )

        try store.save(entry)
    }

    private func hasContent(_ input: CreateEntryInput) -> Bool {
        !input.text.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

struct SaveEntryUseCaseTests {
    @Test
    func init_doesNotRequestSave() {
        let (_, store) = makeSUT()
        #expect(store.createdEntries.isEmpty)
    }

    @Test
    func save_requestsStoreToSaveEntryOnTextOnlyInput() throws {
        let (sut, store) = makeSUT()
        
        try sut.save(anyTextInput())

        #expect(store.createdEntries.count == 1)
        #expect(store.createdEntries.first?.text == "Any text")
    }

    @Test
    func save_throwsInvalidInputErrorOnEmptyInput() {
        let (sut, store) = makeSUT()
        #expect(throws: LocalEntrySaver.Error.invalidInput) {
            try sut.save(CreateEntryInput(text: ""))
        }
        #expect(store.createdEntries.isEmpty)
    }

    @Test
    func save_deliversErrorOnStoreSaveFailure() throws {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        store.stub(expectedError)
        let input = anyTextInput()

        #expect(throws: expectedError) {
            try sut.save(input)
        }
        
        #expect(store.createdEntries.count == 1)
        #expect(store.createdEntries.first?.text == input.text)
    }

    @Test
    func save_throwsInvalidInputErrorOnWhitespaceOnlyInput() {
        let (sut, store) = makeSUT()

        #expect(throws: LocalEntrySaver.Error.invalidInput) {
            try sut.save(CreateEntryInput(text: "   "))
        }

        #expect(store.createdEntries.isEmpty)
    }

    @Test
    func save_createsEntryWithGeneratedIDAndCreationDate() throws {
        let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let fixedDate = Date(timeIntervalSince1970: 1598627222)
        let input = anyTextInput()
        
        let (sut, store) = makeSUT(
            idGenerator: { fixedID },
            dateGenerator: { fixedDate }
        )
        
        try sut.save(input)
        
        let savedEntry = try #require(store.createdEntries.first)
        #expect(savedEntry.id == fixedID)
        #expect(savedEntry.text == input.text)
        #expect(savedEntry.createdAt == fixedDate)
    }

    // MARK: - Helpers

    private func makeSUT(
        idGenerator: @escaping () -> UUID = UUID.init,
        dateGenerator: @escaping () -> Date = Date.init
    ) -> (
        sut: LocalEntrySaver,
        store: EntryStoreSpy
    ) {
        let store = EntryStoreSpy()
        let sut = LocalEntrySaver(
            store: store,
            idGenerator: idGenerator,
            dateGenerator: dateGenerator
        )
        return (sut, store)
    }

    private final class EntryStoreSpy: EntryStore {

        private(set) var createdEntries = [Entry]()
        private var saveError: Error?

        func save(_ entry: Entry) throws {
            createdEntries.append(entry)

            if let error = saveError {
                throw error
            }
        }

        func stub(_ error: Swift.Error) {
            self.saveError = error
        }
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
    
    private func makeEntry(
        id: UUID = UUID(),
        text: String = "Any text",
        createdAt: Date = Date()
    ) -> Entry {
        Entry(id: id, text: text, createdAt: createdAt)
    }

    private func anyTextInput() -> CreateEntryInput {
        CreateEntryInput(text: "Any text")
    }
}
