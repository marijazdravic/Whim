import Testing
import Whim

struct EntryListViewModelTests {
    @Test
    @MainActor
    func init_doesNotRequestLoadEntries() {
        let (_, loader) = makeSUT()

        #expect(loader.receivedMessages.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private func makeSUT() -> (sut: EntryListViewModel, loader: LoadEntriesSpy) {
        let loader = LoadEntriesSpy()
        let sut = EntryListViewModel(loader: loader.loadEntries)
        return (sut, loader)
    }
}

private final class LoadEntriesSpy {
    enum ReceivedMessage: Equatable {
        case load
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    var loadEntries: LoadEntries {
        {
            self.receivedMessages.append(.load)
            return []
        }
    }
}
