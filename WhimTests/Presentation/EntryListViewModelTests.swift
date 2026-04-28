import Foundation
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

        loader.complete()
        await task.value
    }

    @Test
    func loadEntries_setsLoadingStateWhileLoading() async {
        let (sut, loader) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        #expect(sut.isLoading == true)

        loader.complete(with: [])
        await task.value

        #expect(sut.isLoading == false)
    }

    @Test
    func loadEntries_doesNotRequestLoaderAgainWhileLoading() async {
        let (sut, loader) = makeSUT()

        let firstTask = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.completeAdditionalRequestsImmediately()

        await sut.loadEntries()

        #expect(loader.loadCallCount == 1)

        loader.complete()
        await firstTask.value
    }

    @Test
    func loadEntries_deliversLoadedEntriesOnLoaderSuccess() async {
        let (sut, loader) = makeSUT()
        let entry = anyEntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            text: anyText(),
            imageURL: anyImageURL(),
            audioURL: anyAudioURL()
        )

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        loader.complete(with: [entry])
        await task.value

        #expect(sut.entries == [
            EntryDTO(
                id: entry.id,
                text: entry.text,
                imageURL: entry.imageURL,
                audioURL: entry.audioURL
            )
        ])
    }

    @Test
    func loadEntries_deliversErrorMessageOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        loader.fail()
        await task.value

        #expect(sut.errorMessage == EntryListViewModel.loadErrorMessage)
    }

    @Test
    func loadEntries_clearsErrorMessageOnRetry() async {
        let (sut, loader) = makeSUT()

        let failedLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.fail()
        await failedLoad.value

        let retryLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest(at: 1)

        #expect(sut.errorMessage == nil)

        loader.complete()
        await retryLoad.value
    }

    @Test
    func loadErrorMessage_isLocalized() {
        #expect(EntryListViewModel.loadErrorMessage == localized("ENTRY_LIST_LOAD_ERROR"))
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryListViewModel, loader: LoadEntriesSpy) {
        let loader = LoadEntriesSpy()
        let sut = EntryListViewModel(loader: loader.loadEntries)
        return (sut, loader)
    }

    private func localized(_ key: String) -> String {
        Bundle(for: EntryListViewModel.self).localizedString(
            forKey: key,
            value: nil,
            table: "EntryList"
        )
    }
}

@MainActor
private final class LoadEntriesSpy {
    private(set) var loadCallCount = 0
    private var completesAdditionalRequestsImmediately = false
    private var continuations = [CheckedContinuation<[Entry], Error>]()

    var loadEntries: LoadEntries {
        {
            self.loadCallCount += 1
            
            if self.completesAdditionalRequestsImmediately && self.loadCallCount > 1 {
                return []
            }
            
            return try await withCheckedThrowingContinuation { continuation in
                self.continuations.append(continuation)
            }
        }
    }

    func waitForLoadRequest(at index: Int = 0) async {
        while loadCallCount <= index {
            await Task.yield()
        }
    }

    func complete(with entries: [Entry] = [], at index: Int = 0) {
        continuations.remove(at: index).resume(returning: entries)
    }

    func fail(with error: Error = anyNSError(), at index: Int = 0) {
        continuations.remove(at: index).resume(throwing: error)
    }

    func completeAdditionalRequestsImmediately() {
        completesAdditionalRequestsImmediately = true
    }
}
