import Foundation
import Testing
import SwiftData
import Whim

struct SwiftDataEntryStoreTests {
    @Test
    func insert_persistsEntry() throws {
        let (sut, container) = try makeSUT()
        let entry = Entry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            text: "Any text",
            imageURL: URL(string: "file:///some/image.jpg"),
            audioURL: URL(string: "file:///some/audio.m4a"),
            createdAt: Date(timeIntervalSince1970: 123),
            status: .draft
        )
        
        try sut.insert(entry)

        let saved = try fetchEntries(from: container)
        #expect(saved.count == 1)
        let model = try #require(saved.first)
        #expect(model.id == entry.id)
        #expect(model.text == entry.text)
        #expect(model.imageURL == entry.imageURL)
        #expect(model.audioURL == entry.audioURL)
        #expect(model.createdAt == entry.createdAt)
        #expect(model.status == "draft")
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
        let (sut, _) = try makeSUT()
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

    @Test
    func entryStatus_initLocalValue_deliversDraftOnDraftValue() throws {
        let status = try EntryStatus(localValue: "draft")

        #expect(status == .draft)
    }

    @Test
    func entryStatus_initLocalValue_throwsOnInvalidValue() {
        #expect(throws: EntryStatusMappingError.invalidStatus("invalid")) {
            try EntryStatus(localValue: "invalid")
        }
    }

    // MARK: - Helpers
    
    private func makeSUT() throws -> (SwiftDataEntryStore, ModelContainer) {
        return try SwiftDataEntryStore(inMemory: true)
            for: EntryDataModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return (SwiftDataEntryStore(container: container), container)
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
    
    private func fetchEntries(from container: ModelContainer) throws -> [EntryDataModel] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<EntryDataModel>())
    }
}
