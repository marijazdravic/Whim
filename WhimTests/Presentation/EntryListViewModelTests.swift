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
    func loadEntries_stopsLoadingOnLoaderFailure() async {
        let (sut, loader) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        loader.fail()
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

        #expect(sut.entries.count == 1)
        #expect(sut.entries.first?.id == entry.id)
        #expect(sut.entries.first?.text == entry.text)
        #expect(sut.entries.first?.imageURL == entry.imageURL)
        #expect(sut.entries.first?.audioURL == entry.audioURL)
    }

    @Test
    func loadEntries_deliversEntriesInOrderProvidedByLoader() async {
        let (sut, loader) = makeSUT()
        let entry1 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        let entry2 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!)
        let entry3 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!)

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.complete(with: [entry1, entry2, entry3])
        await task.value

        #expect(sut.entries.map(\.id) == [entry1.id, entry2.id, entry3.id])
    }

    @Test
    func loadEntries_replacesLoadedEntriesWithEmptyListOnEmptyLoaderResult() async {
        let (sut, loader) = makeSUT()
        let entry = anyEntry()

        let firstLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.complete(with: [entry])
        await firstLoad.value

        let secondLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest(at: 1)
        loader.complete(with: [])
        await secondLoad.value

        #expect(sut.entries.isEmpty)
    }

    @Test
    func loadEntries_mapsEntryCreatedDatesToRelativeTimestamps() async {
        let calendar = Calendar(identifier: .gregorian)
        let locale = Locale(identifier: "en_US_POSIX")
        let currentDate = Date(timeIntervalSince1970: 1000)
        let samples = [
            (
                entry: anyEntry(
                    id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
                    createdAt: currentDate.adding(minutes: -5, calendar: calendar)
                ),
                timestamp: "5 minutes ago"
            ),
            (
                entry: anyEntry(
                    id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
                    createdAt: currentDate.adding(days: -1, calendar: calendar)
                ),
                timestamp: "1 day ago"
            )
        ]
        let (sut, loader) = makeSUT(
            currentDate: { currentDate },
            calendar: calendar,
            locale: locale
        )

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        loader.complete(with: samples.map { $0.entry })
        await task.value

        #expect(sut.entries.map(\.timestamp) == samples.map { $0.timestamp })
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
    func loadEntries_preservesPreviouslyLoadedEntriesOnFailure() async {
        let (sut, loader) = makeSUT()
        let entry = anyEntry()

        let firstLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.complete(with: [entry])
        await firstLoad.value
        let previouslyLoadedEntries = sut.entries

        let retryLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest(at: 1)
        loader.fail()
        await retryLoad.value

        #expect(sut.entries == previouslyLoadedEntries)
    }

    @Test
    func loadEntries_preservesPreviouslyLoadedEntriesWhileLoading() async {
        let (sut, loader) = makeSUT()
        let entry = anyEntry()

        let firstLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.complete(with: [entry])
        await firstLoad.value
        let previouslyLoadedEntries = sut.entries

        let retryLoad = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest(at: 1)

        #expect(sut.entries == previouslyLoadedEntries)

        loader.complete()
        await retryLoad.value
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

    @Test
    func delete_requestsEntryDeletionWithID() async {
        let (sut, _, deleter) = makeDeleteSUT()
        let id = anyEntryID()

        await sut.delete(id)

        #expect(deleter.deletedIDs == [id])
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping () -> Date = anyEntryDate,
        calendar: Calendar = Calendar(identifier: .gregorian),
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> (sut: EntryListViewModel, loader: LoadEntriesSpy) {
        let loader = LoadEntriesSpy()
        let sut = EntryListViewModel(
            loader: loader.loadEntries,
            currentDate: currentDate,
            calendar: calendar,
            locale: locale
        )
        return (sut, loader)
    }

    private func makeDeleteSUT() -> (sut: EntryListViewModel, loader: LoadEntriesSpy, deleter: DeleteEntrySpy) {
        let loader = LoadEntriesSpy()
        let deleter = DeleteEntrySpy()
        let sut = EntryListViewModel(loader: loader.loadEntries, delete: deleter.delete)
        return (sut, loader, deleter)
    }

    private func localized(_ key: String) -> String {
        let table = "EntryList"
        let value = Bundle(for: EntryListViewModel.self).localizedString(
            forKey: key,
            value: nil,
            table: table
        )

        #expect(value != key, "Missing localized string for key: \(key) in table: \(table)")

        return value
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

@MainActor
private final class DeleteEntrySpy {
    private(set) var deletedIDs = [UUID]()

    func delete(_ id: UUID) {
        deletedIDs.append(id)
    }
}
