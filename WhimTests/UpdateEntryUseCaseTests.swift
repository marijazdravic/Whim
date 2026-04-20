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
        
        try? sut.apply(.setText(anyText()), to: id)
        
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
    func apply_setText_updatesTextPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let existingEntry = anyEntry(text: "Old text")
        let expectedEntry = anyEntry(
            id: existingEntry.id,
            text: "New text",
            imageURL: existingEntry.imageURL,
            audioURL: existingEntry.audioURL,
            createdAt: existingEntry.createdAt
        )
        store.stubRetrieve(with: existingEntry)

        try expect(sut, toSend: [.retrieve(existingEntry.id), .update(expectedEntry)], to: store, when: {
            try sut.apply(.setText("New text"), to: existingEntry.id)
        })
    }

    @Test
    func apply_clearText_clearsTextPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let existingEntry = anyEntry(text: "Some text")
        let expectedEntry = anyEntry(
            id: existingEntry.id,
            text: nil,
            imageURL: existingEntry.imageURL,
            audioURL: existingEntry.audioURL,
            createdAt: existingEntry.createdAt
        )
        store.stubRetrieve(with: existingEntry)

        try expect(sut, toSend: [.retrieve(existingEntry.id), .update(expectedEntry)], to: store, when: {
            try sut.apply(.clearText, to: existingEntry.id)
        })
    }
    
    @Test
    func apply_setImage_updatesImageURLPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let existingEntry = anyEntry(imageURL: nil)
        let newImageURL = anyImageURL()
        let expectedEntry = anyEntry(
            id: existingEntry.id,
            text: existingEntry.text,
            imageURL: newImageURL,
            audioURL: existingEntry.audioURL,
            createdAt: existingEntry.createdAt
        )
        store.stubRetrieve(with: existingEntry)

        try expect(sut, toSend: [.retrieve(existingEntry.id), .update(expectedEntry)], to: store, when: {
            try sut.apply(.setImage(newImageURL), to: existingEntry.id)
        })
    }
    
    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }

    private func expect(
        _ sut: EntryUpdater,
        toSend expectedMessages: [EntryStoreSpy.ReceivedMessage],
        to store: EntryStoreSpy,
        when action: () throws -> Void,
        sourceLocation: SourceLocation = #_sourceLocation
    ) rethrows {
        try action()

        #expect(
            store.receivedMessages == expectedMessages,
            sourceLocation: sourceLocation
        )
    }
}
