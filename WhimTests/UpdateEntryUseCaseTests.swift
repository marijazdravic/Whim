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
        guard try store.retrieve(by: id) != nil else {
            throw Error.notFound
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

    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }
}
