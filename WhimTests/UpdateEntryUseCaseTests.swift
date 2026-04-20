import Foundation
import Testing
import Whim

enum EntryUpdate {
    case setText(String)
}

final class EntryUpdater {
    let store: EntryStore
    
    init(store: EntryStore) {
        self.store = store
    }
    
    func apply(_ update: EntryUpdate, to id: UUID) throws {
        _ = try store.retrieve(by: id)
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
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }
}
