import Foundation
import Testing
import Whim

final class EntryUpdater {
    
    init(store: EntryStore) {}
}

struct EntryUpdaterTests {
    @Test
    func init_doesNotRequestStoreUpdate() {
        let (_, store) = makeSUT()

        #expect(store.receivedMessages.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }
}
