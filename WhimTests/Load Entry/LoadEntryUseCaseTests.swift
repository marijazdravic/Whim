import Testing
import Foundation
import Whim

struct EntryLoaderTests {
    @Test
    func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        #expect(store.receivedMessages.isEmpty)
    }

    @Test
    func load_requestsStoreRetrievalOnce() throws {
        let (sut, store) = makeSUT()

        _ = try sut.load()

        #expect(store.receivedMessages == [.retrieveAll])
    }

    @Test
    func load_deliversEmptyListOnEmptyStore() throws {
        let (sut, _) = makeSUT()

        let loaded = try sut.load()

        #expect(loaded == [])
    }

    @Test
    func load_deliversPersistedEntriesNewestFirst() throws {
        let (sut, store) = makeSUT()
        let newest = anyEntry(id: UUID(), createdAt: Date(timeIntervalSince1970: 2))
        let oldest = anyEntry(id: UUID(), createdAt: Date(timeIntervalSince1970: 1))
        store.stubRetrieveAll(with: [oldest, newest])

        let loaded = try sut.load()

        #expect(loaded == [newest, oldest])
    }

    @Test
    func load_deliversErrorOnStoreRetrievalFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        store.stubRetrieveAll(with: expectedError)

        #expect(throws: expectedError) {
            try sut.load()
        }

        #expect(store.receivedMessages == [.retrieveAll])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryLoader, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryLoader(store: store)
        return (sut, store)
    }
}
