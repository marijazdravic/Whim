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
        let (existing, expected) = anyEntries(existingText: "Old text", expectedText: "New text")
        store.stubRetrieval(with: existing)
        
        try expect(toSend: [.retrieve(existing.id), .update(expected)], to: store, when: {
            try sut.apply(.setText("New text"), to: existing.id)
        })
    }
    
    @Test
    func apply_clearText_clearsTextPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let (existing, expected) = anyEntries(existingText: "Some text", expectedText: nil)
        store.stubRetrieval(with: existing)
        
        try expect(toSend: [.retrieve(existing.id), .update(expected)], to: store, when: {
            try sut.apply(.clearText, to: existing.id)
        })
    }
    
    @Test
    func apply_setImage_updatesImageURLPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let newImageURL = anyImageURL()
        let (existing, expected) = anyEntries(existingImageURL: nil, expectedImageURL: newImageURL)
        store.stubRetrieval(with: existing)
        
        try expect(toSend: [.retrieve(existing.id), .update(expected)], to: store, when: {
            try sut.apply(.setImage(newImageURL), to: existing.id)
        })
    }
    
    @Test
    func apply_deliversErrorOnStoreUpdateFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        let (existing, expected) = anyEntries(existingText: "Old text", expectedText: "New text")
        store.stubRetrieval(with: existing)
        store.stubUpdate(with: expectedError)
        
        #expect(throws: expectedError) {
            try sut.apply(.setText("New text"), to: existing.id)
        }
        
        #expect(store.receivedMessages == [
            .retrieve(existing.id),
            .update(expected)
        ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }
    
    
    private func expect(
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
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
    
    private func anyEntries(
        id: UUID = anyEntryID(),
        existingText: String? = anyText(),
        expectedText: String? = anyText(),
        existingImageURL: URL? = anyImageURL(),
        expectedImageURL: URL? = anyImageURL(),
        existingAudioURL: URL? = anyAudioURL(),
        expectedAudioURL: URL? = anyAudioURL(),
        createdAt: Date = anyEntryDate()
    ) -> (existing: Entry, expected: Entry) {
        (
            existing: Entry(
                id: id,
                text: existingText,
                imageURL: existingImageURL,
                audioURL: existingAudioURL,
                createdAt: createdAt
            ),
            expected: Entry(
                id: id,
                text: expectedText,
                imageURL: expectedImageURL,
                audioURL: expectedAudioURL,
                createdAt: createdAt
            )
        )
    }
}
