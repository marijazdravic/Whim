import Foundation
import Testing
import Whim

struct EntryDeleterTests {
    @Test
    func init_doesNotRequestStoreMessages() {
        let (_, store) = makeSUT()

        #expect(store.receivedMessages.isEmpty)
    }

    @Test
    func delete_requestsStoreToDeleteByID() throws {
        let (sut, store) = makeSUT()
        let id = anyEntryID()

        try sut.delete(by: id)

        #expect(store.receivedMessages == [.delete(id)])
    }

    @Test
    func delete_deliversErrorOnStoreDeletionFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        let id = anyEntryID()
        store.stubDeletion(with: expectedError)

        #expect(throws: expectedError) {
            try sut.delete(by: id)
        }

        #expect(store.receivedMessages == [.delete(id)])
    }

    // MARK: - Helpers

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private func makeSUT() -> (sut: EntryDeleter, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryDeleter(store: store)
        return (sut, store)
    }
}
