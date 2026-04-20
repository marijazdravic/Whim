import Foundation
import Testing
import Whim

enum EntryUpdate {
    case setText(String)
    case clearText
    case setImage(URL)
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
        
        let updatedEntry: Entry
        switch update {
        case let .setText(text):
            updatedEntry = Entry(
                id: entry.id,
                text: text,
                imageURL: entry.imageURL,
                audioURL: entry.audioURL,
                createdAt: entry.createdAt
            )
            
        case .clearText:
            updatedEntry = Entry(
                id: entry.id,
                text: nil,
                imageURL: entry.imageURL,
                audioURL: entry.audioURL,
                createdAt: entry.createdAt
            )
            
        case let .setImage(url):
            updatedEntry = Entry(
                id: entry.id,
                text: entry.text,
                imageURL: url,
                audioURL: entry.audioURL,
                createdAt: entry.createdAt
            )
        }
        
        try store.update(updatedEntry)
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
    func apply_deliversNotFoundErrorWithoutRequestingStoreUpdateWhenEntryDoesNotExist() {
        let (sut, store) = makeSUT()
        let id = UUID()

        #expect(throws: EntryUpdater.Error.notFound) {
            try sut.apply(.setText(anyText()), to: id)
        }

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
    
    @Test
    func apply_clearText_clearsTextPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let id = UUID()
        let createdAt = anyEntryDate()
        let imageURL = anyImageURL()
        let audioURL = anyAudioURL()
        let existingEntry = anyEntry(
            id: id,
            text: "Some text",
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )
        
        store.stubRetrieve(with: existingEntry)
        
        try sut.apply(.clearText, to: id)
        
        let expectedEntry = anyEntry(
            id: id,
            text: nil,
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )
        
        #expect(store.receivedMessages == [
            .retrieve(id),
            .update(expectedEntry)
        ])
    }
    
    @Test
    func apply_setImage_updatesEntryImageURLPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let id = UUID()
        let createdAt = anyEntryDate()
        let text = anyText()
        let audioURL = anyAudioURL()
        let existingEntry = anyEntry(
            id: id,
            text: text,
            imageURL: nil,
            audioURL: audioURL,
            createdAt: createdAt
        )
        let newImageURL = anyImageURL()
        
        store.stubRetrieve(with: existingEntry)
        
        try sut.apply(.setImage(newImageURL), to: id)
        
        let expectedEntry = anyEntry(
            id: id,
            text: text,
            imageURL: newImageURL,
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
