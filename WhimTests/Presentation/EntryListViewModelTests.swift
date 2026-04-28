import Testing
import Whim

@MainActor
struct EntryListViewModelTests {
    @Test
    func init_doesNotRequestLoadEntries() {
        let (_, loader) = makeSUT()

        #expect(loader.loadCallCount == 0)
    }

    @Test
    func loadEntries_requestsLoaderToLoadEntries() async {
        let (sut, loader) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        #expect(loader.loadCallCount == 1)

        await loader.complete()
        await task.value
    }

    @Test
    func loadEntries_setsLoadingStateWhileLoading() async {
        let (sut, loader) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        #expect(sut.isLoading == true)

        await loader.complete(with: [])
        await task.value

        #expect(sut.isLoading == false)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryListViewModel, loader: LoadEntriesSpy) {
        let loader = LoadEntriesSpy()
        let sut = EntryListViewModel(loader: loader.loadEntries)
        return (sut, loader)
    }
}

@MainActor
private final class LoadEntriesSpy {
    private(set) var loadCallCount = 0
    private var continuation: CheckedContinuation<[Entry], Error>?

    var loadEntries: LoadEntries {
        {
            self.loadCallCount += 1
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
    }

    func waitForLoadRequest() async {
        while loadCallCount == 0 {
            await Task.yield()
        }
    }

    func complete(with entries: [Entry] = []) {
        continuation?.resume(returning: entries)
        continuation = nil
    }
}
