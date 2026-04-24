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
    func load_sortsEntriesWithEqualCreatedAtByIDAscending() throws {
        let (sut, store) = makeSUT()
        let sharedDate = anyEntryDate()
        let first = anyEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: sharedDate
        )
        let second = anyEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            createdAt: sharedDate
        )
        store.stubRetrieveAll(with: [second, first])

        let loaded = try sut.load()

        #expect(loaded == [first, second])
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
