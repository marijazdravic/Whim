import Foundation
import Testing
import Whim

struct SwiftDataEntryStoreTests {
    @Test
    func retrieve_deliversNoEntryOnEmptyStore() throws {
        let sut = try makeSUT()

        let result = try sut.retrieve(by: UUID())

        #expect(result == nil)
    }

    @Test
    func retrieve_deliversEntryForPersistedID() throws {
        let sut = try makeSUT()
        let entry = anyEntry()
        try sut.insert(entry)

        let retrieved = try sut.retrieve(by: entry.id)

        #expect(retrieved == entry)
    }

    @Test
    func retrieve_deliversNoEntryForNonMatchingID() throws {
        let sut = try makeSUT()

        try sut.insert(anyEntry())

        let result = try sut.retrieve(by: UUID())
        #expect(result == nil)
    }

    @Test
    func retrieve_hasNoSideEffectsOnEmptyStore() throws {
        let sut = try makeSUT()
        let id = UUID()

        let firstResult = try sut.retrieve(by: id)
        let secondResult = try sut.retrieve(by: id)
        #expect(firstResult == nil)
        #expect(secondResult == nil)
    }

    @Test
    func retrieve_hasNoSideEffectsOnPersistedEntry() throws {
        let sut = try makeSUT()
        let entry = anyEntry()

        try sut.insert(entry)

        let firstResult = try sut.retrieve(by: entry.id)
        let secondResult = try sut.retrieve(by: entry.id)
        #expect(firstResult == entry)
        #expect(secondResult == entry)
    }

    @Test
    func retrieve_deliversCorrectEntryAmongMultiplePersistedEntries() throws {
        let sut = try makeSUT()
        let first = anyEntry(id: UUID())
        let second = anyEntry(id: UUID())

        try sut.insert(first)
        try sut.insert(second)

        let retrieved = try sut.retrieve(by: second.id)

        #expect(retrieved == second)
    }

    @Test
    func insert_throwsOnDuplicateID() throws {
        let sut = try makeSUT()
        let id = UUID()
        let first = anyEntry(id: id)
        let second = anyEntry(id: id)

        try sut.insert(first)

        #expect(throws: SwiftDataEntryStoreError.duplicateID) {
            try sut.insert(second)
        }
    }

    @Test
    func delete_removesPersistedEntry() throws {
        let sut = try makeSUT()
        let entry = anyEntry()

        try sut.insert(entry)
        try sut.delete(by: entry.id)

        #expect(try sut.retrieve(by: entry.id) == nil)
    }

    @Test
    func delete_preservesOtherPersistedEntries() throws {
        let sut = try makeSUT()
        let first = anyEntry(id: UUID())
        let second = anyEntry(id: UUID())

        try sut.insert(first)
        try sut.insert(second)
        try sut.delete(by: first.id)

        #expect(try sut.retrieve(by: first.id) == nil)
        #expect(try sut.retrieve(by: second.id) == second)
    }

    @Test
    func delete_hasNoEffectWhenEntryDoesNotExist() throws {
        let sut = try makeSUT()

        #expect(throws: Never.self) {
            try sut.delete(by: UUID())
        }
    }

    @Test
    func delete_hasNoEffectWhenDeletingNonMatchingID() throws {
        let sut = try makeSUT()
        let entry = anyEntry()

        try sut.insert(entry)
        try sut.delete(by: UUID())

        #expect(try sut.retrieve(by: entry.id) == entry)
    }

    @Test
    func update_modifiesPersistedEntry() throws {
        let sut = try makeSUT()
        let original = anyEntry(text: anyText())
        let updated = anyEntry(id: original.id, text: updatedText())

        try sut.insert(original)
        try sut.update(updated)

        #expect(try sut.retrieve(by: original.id) == updated)
    }

    @Test
    func update_preservesOtherPersistedEntries() throws {
        let sut = try makeSUT()
        let first = anyEntry(id: UUID(), text: anyText())
        let second = anyEntry(id: UUID(), text: updatedText())
        let updatedFirst = anyEntry(id: first.id, text: "Updated first")

        try sut.insert(first)
        try sut.insert(second)
        try sut.update(updatedFirst)

        #expect(try sut.retrieve(by: first.id) == updatedFirst)
        #expect(try sut.retrieve(by: second.id) == second)
    }

    @Test
    func update_preservesUnchangedFields() throws {
        let sut = try makeSUT()
        let original = anyEntry()
        let updated = anyEntry(
            id: original.id,
            text: updatedText(),
            imageURL: original.imageURL,
            audioURL: original.audioURL,
            createdAt: original.createdAt
        )

        try sut.insert(original)
        try sut.update(updated)

        let retrieved = try sut.retrieve(by: original.id)
        #expect(retrieved?.text == updatedText())
        #expect(retrieved?.imageURL == original.imageURL)
        #expect(retrieved?.audioURL == original.audioURL)
        #expect(retrieved?.createdAt == original.createdAt)
    }

    @Test
    func update_throwsNotFoundWhenEntryDoesNotExist() throws {
        let sut = try makeSUT()
        let nonExistent = anyEntry(id: anyEntryID())

        #expect(throws: SwiftDataEntryStoreError.notFound) {
            try sut.update(nonExistent)
        }
        #expect(try sut.retrieve(by: nonExistent.id) == nil)
    }

    @Test
    func update_throwsNotFoundWhenUpdatingNonMatchingIDAmongPersistedEntries() throws {
        let sut = try makeSUT()
        let existing = anyEntry()
        let nonMatching = anyEntry(id: UUID(), text: updatedText())

        try sut.insert(existing)

        #expect(throws: SwiftDataEntryStoreError.notFound) {
            try sut.update(nonMatching)
        }
        #expect(try sut.retrieve(by: existing.id) == existing)
    }

    // MARK: - Helpers

    private func makeSUT() throws -> SwiftDataEntryStore {
        try SwiftDataEntryStore(inMemory: true)
    }
}
