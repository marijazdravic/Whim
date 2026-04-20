import Foundation
import Testing
import Whim

enum EntryUpdate {
    case setText(String)
}

final class EntryUpdater {
    enum Error: Swift.Error {
        case notFound
    }
    
    let store: EntryStore
    
    init(store: EntryStore) {
        self.store = store
    }
    
    func apply(_ update: EntryUpdate, to id: UUID) throws {
        guard let entry = try store.retrieve(by: id) else {
            throw Error.notFound
        }
        
        switch update {
        case let .setText(text):
            let updatedEntry = Entry(
                id: entry.id,
                text: text,
                imageURL: entry.imageURL,
                audioURL: entry.audioURL,
                createdAt: entry.createdAt
            )
            
            try store.update(updatedEntry)
        }
    }
}

struct EntryUpdaterTests {
    @Test
    func init_doesNotRequestStoreMessages() {
        let (_, store) = makeSUT()
        
        #expect(store.receivedMessages.isEmpty)
    }
    
    @Test
    func apply_requestsStoreToRetrieveEntryByID() throws {
        let (sut, store) = makeSUT()
        let id = UUID()
        
        try? sut.apply(.setText("Updated text"), to: id)
        
        #expect(store.receivedMessages == [.retrieve(id)])
    }
    
    @Test
    func apply_throwsNotFoundWhenEntryDoesNotExist() {
        let (sut, _) = makeSUT()
        
        let id = UUID()
        
        #expect(throws: EntryUpdater.Error.notFound) {
            try sut.apply(.setText(anyText()), to: id)
        }
    }
    
    @Test
    func apply_doesNotRequestStoreUpdateWhenEntryDoesNotExist() {
        let (sut, store) = makeSUT()
        
        let id = UUID()
        
        try? sut.apply(.setText("Any text"), to: id)
        
        #expect(store.receivedMessages == [.retrieve(id)])
    }
    
    @Test
    func apply_setText_updatesEntryTextPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let id = UUID()
        let createdAt = anyEntryDate()
        let imageURL = anyImageURL()
        let audioURL = anyAudioURL()
        let existingEntry = anyEntry(
            id: id,
            text: "Old text",
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )

        store.stubRetrieve(with: existingEntry)

        try sut.apply(.setText("New text"), to: id)

        let expectedEntry = anyEntry(
            id: id,
            text: "New text",
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )

        #expect(store.receivedMessages == [
            .retrieve(id),
            .update(expectedEntry)
        ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }
}
