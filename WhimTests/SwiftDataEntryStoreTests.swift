import Foundation
import Testing
import Whim

struct SwiftDataEntryStoreTests {
    @Test
    func insert_persistsEntry() throws {
        let sut = try makeSUT()
        let entry = Entry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            text: "Any text",
            imageURL: URL(string: "file:///some/image.jpg"),
            audioURL: URL(string: "file:///some/audio.m4a"),
            createdAt: Date(timeIntervalSince1970: 123),
            status: .draft
        )

        try sut.insert(entry)

        let retrieved = try sut.retrieve(by: entry.id)
        #expect(retrieved == entry)
    }
    
    @Test
    func retrieve_deliversNoEntryOnEmptyStore() throws {
        let sut = try makeSUT()

        let result = try sut.retrieve(by: UUID())

        #expect(result == nil)
    }

    @Test
    func retrieve_deliversEntryForPersistedID() throws {
        let sut = try makeSUT()
        let entry = Entry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            text: "Any text",
            imageURL: URL(string: "file:///some/image.jpg"),
            audioURL: URL(string: "file:///some/audio.m4a"),
            createdAt: Date(timeIntervalSince1970: 123),
            status: .draft
        )

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
        let entry = Entry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            text: "Any text",
            imageURL: URL(string: "file:///some/image.jpg"),
            audioURL: URL(string: "file:///some/audio.m4a"),
            createdAt: Date(timeIntervalSince1970: 123),
            status: .draft
        )

        try sut.insert(entry)

        let firstResult = try sut.retrieve(by: entry.id)
        let secondResult = try sut.retrieve(by: entry.id)
        #expect(firstResult == entry)
        #expect(secondResult == entry)
    }

    // MARK: - Helpers
    
    private func makeSUT() throws -> SwiftDataEntryStore {
        return try SwiftDataEntryStore(inMemory: true)
    }

    private func anyEntry() -> Entry {
        Entry(
            id: UUID(),
            text: "Any text",
            imageURL: nil,
            audioURL: nil,
            createdAt: Date(),
            status: .draft
        )
    }
    
}
