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
        let first = anyEntry()
        let second = anyEntry()

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

    // MARK: - Helpers

    private func makeSUT() throws -> SwiftDataEntryStore {
        try SwiftDataEntryStore(inMemory: true)
    }

    private func anyEntry(id: UUID = anyEntryID()) -> Entry {
        Entry(
            id: id,
            text: anyText(),
            imageURL: nil,
            audioURL: nil,
            createdAt: anyEntryDate(),
            status: .draft
        )
    }
}
