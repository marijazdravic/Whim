import Foundation
import Testing
import Whim

@MainActor
struct EntryListViewModelTests {
    @Test
    func init_doesNotRequestLoadEntries() {
        let (_, loader, _) = makeSUT()

        #expect(loader.loadCallCount == 0)
    }

    @Test
    func loadEntries_requestsLoaderToLoadEntries() async {
        let (sut, loader, _) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        #expect(loader.loadCallCount == 1)

        loader.complete()
        await task.value
    }

    @Test
    func loadEntries_setsLoadingStateWhileLoading() async {
        let (sut, loader, _) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        #expect(sut.isLoading == true)

        loader.complete(with: [])
        await task.value

        #expect(sut.isLoading == false)
    }

    @Test
    func loadEntries_stopsLoadingOnLoaderFailure() async {
        let (sut, loader, _) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        loader.fail()
        await task.value

        #expect(sut.isLoading == false)
    }

    @Test
    func loadEntries_doesNotRequestLoaderAgainWhileLoading() async {
        let (sut, loader, _) = makeSUT()

        let firstTask = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        await sut.loadEntries()

        #expect(loader.loadCallCount == 1)

        loader.complete()
        await firstTask.value
    }

    @Test
    func loadEntries_deliversLoadedEntriesOnLoaderSuccess() async {
        let (sut, loader, _) = makeSUT()
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
        let (sut, loader, _) = makeSUT()
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
        let (sut, loader, _) = makeSUT()
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
        let (sut, loader, _) = makeSUT(
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
        let (sut, loader, _) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()

        loader.fail()
        await task.value

        #expect(sut.errorMessage == EntryListViewModel.loadErrorMessage)
    }

    @Test
    func loadEntries_preservesPreviouslyLoadedEntriesOnFailure() async {
        let (sut, loader, _) = makeSUT()
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
        let (sut, loader, _) = makeSUT()
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
        let (sut, loader, _) = makeSUT()

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
    func deleteErrorMessage_isLocalized() {
        #expect(EntryListViewModel.deleteErrorMessage == localized("ENTRY_LIST_DELETE_ERROR"))
    }

    @Test
    func delete_requestsEntryDeletionWithID() async {
        let (sut, _, deleter) = makeSUT()
        let id = anyEntryID()

        await sut.delete(id)

        #expect(deleter.deletedIDs == [id])
    }

    @Test
    func delete_removesEntryFromListOnSuccess() async {
        let (sut, loader, _) = makeSUT()
        let entry1 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        let entry2 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!)

        let loadTask = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.complete(with: [entry1, entry2])
        await loadTask.value

        await sut.delete(entry1.id)

        #expect(sut.entries.map(\.id) == [entry2.id])
    }

    @Test
    func delete_preservesEntriesOnFailure() async {
        let (sut, loader, deleter) = makeSUT()
        let entry1 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        let entry2 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!)

        let loadTask = Task { await sut.loadEntries() }
        await loader.waitForLoadRequest()
        loader.complete(with: [entry1, entry2])
        await loadTask.value
        let loadedEntries = sut.entries

        deleter.stubDeletion(with: anyNSError())
        await sut.delete(entry1.id)

        #expect(sut.entries == loadedEntries)
    }

    @Test
    func delete_deliversErrorMessageOnDeletionFailure() async {
        let (sut, _, deleter) = makeSUT()

        deleter.stubDeletion(with: anyNSError())
        await sut.delete(anyEntryID())

        #expect(sut.errorMessage == EntryListViewModel.deleteErrorMessage)
    }

    @Test
    func delete_clearsErrorMessageOnRetry() async {
        let (sut, _, deleter) = makeSUT()
        let id = anyEntryID()

        deleter.stubDeletion(with: anyNSError())
        await sut.delete(id)

        deleter.stubPendingDeletion()
        let retryDeletion = Task { await sut.delete(id) }
        await deleter.waitForDeleteRequest(at: 1)

        #expect(sut.errorMessage == nil)

        deleter.complete()
        await retryDeletion.value
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping () -> Date = anyEntryDate,
        calendar: Calendar = Calendar(identifier: .gregorian),
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> (sut: EntryListViewModel, loader: LoadEntriesSpy, deleter: DeleteEntrySpy) {
        let loader = LoadEntriesSpy()
        let deleter = DeleteEntrySpy()
        let sut = EntryListViewModel(
            loader: loader.loadEntries,
            delete: deleter.delete,
            currentDate: currentDate,
            calendar: calendar,
            locale: locale
        )
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
    private var loadRequestWaiters = [(index: Int, continuation: CheckedContinuation<Void, Never>)]()
    private var continuations = [CheckedContinuation<[Entry], Error>]()

    func loadEntries() async throws -> [Entry] {
        loadCallCount += 1
        completeLoadRequestWaiters()

        return try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func waitForLoadRequest(at index: Int = 0) async {
        guard loadCallCount <= index else { return }

        await withCheckedContinuation { continuation in
            loadRequestWaiters.append((index, continuation))
        }
    }

    func complete(with entries: [Entry] = [], at index: Int = 0) {
        continuations.remove(at: index).resume(returning: entries)
    }

    func fail(with error: Error = anyNSError(), at index: Int = 0) {
        continuations.remove(at: index).resume(throwing: error)
    }

    private func completeLoadRequestWaiters() {
        let readyWaiters = loadRequestWaiters.filter { loadCallCount > $0.index }
        loadRequestWaiters.removeAll { loadCallCount > $0.index }
        readyWaiters.forEach { $0.continuation.resume() }
    }
}

@MainActor
private final class DeleteEntrySpy {
    private(set) var deletedIDs = [UUID]()
    private var deletionResult: Result<Void, Error>?
    private var deleteRequestWaiters = [(index: Int, continuation: CheckedContinuation<Void, Never>)]()
    private var continuations = [CheckedContinuation<Void, Error>]()
    private var shouldSuspendDeletion = false

    func delete(_ id: UUID) async throws {
        deletedIDs.append(id)
        completeDeleteRequestWaiters()
        if shouldSuspendDeletion {
            return try await withCheckedThrowingContinuation { continuation in
                continuations.append(continuation)
            }
        }

        try deletionResult?.get()
    }

    func waitForDeleteRequest(at index: Int = 0) async {
        guard deletedIDs.count <= index else { return }

        await withCheckedContinuation { continuation in
            deleteRequestWaiters.append((index, continuation))
        }
    }

    func complete(at index: Int = 0) {
        continuations.remove(at: index).resume()
    }

    func stubDeletion(with error: Error) {
        shouldSuspendDeletion = false
        deletionResult = .failure(error)
    }

    func stubPendingDeletion() {
        shouldSuspendDeletion = true
        deletionResult = nil
    }

    private func completeDeleteRequestWaiters() {
        let readyWaiters = deleteRequestWaiters.filter { deletedIDs.count > $0.index }
        deleteRequestWaiters.removeAll { deletedIDs.count > $0.index }
        readyWaiters.forEach { $0.continuation.resume() }
    }
}
