import Foundation
import Testing
import Whim

private typealias LoadEntriesSpy = AsyncLoaderSpy<Void, [Entry]>
private typealias DeleteEntrySpy = AsyncLoaderSpy<UUID, Void>

@MainActor
struct EntryListViewModelTests {
    @Test
    func init_doesNotRequestCollaborators() {
        let (_, loader, deleter) = makeSUT()

        #expect(loader.requests.isEmpty)
        #expect(deleter.requests.isEmpty)
    }

    @Test
    func loadEntries_requestsLoaderToLoadEntries() async {
        let (sut, loader, _) = makeSUT()

        await loader.completeRequest(with: []) { await sut.loadEntries() }

        #expect(loader.requests.count == 1)
        #expect(loader.resultStates == [.success])
    }

    @Test
    func loadEntries_setsLoadingStateWhileLoading() async {
        let (sut, loader, _) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForRequest()

        #expect(sut.isLoading == true)

        loader.completeRequest(with: [])
        await task.value

        #expect(sut.isLoading == false)
    }

    @Test
    func loadEntries_stopsLoadingOnLoaderFailure() async {
        let (sut, loader, _) = makeSUT()

        await loader.failRequest { await sut.loadEntries() }

        #expect(sut.isLoading == false)
        #expect(loader.resultStates == [.failure])
    }

    @Test
    func loadEntries_doesNotDeliverErrorMessageOnCancellation() async {
        let (sut, loader, _) = makeSUT()

        let task = Task { await sut.loadEntries() }
        await loader.waitForRequest()

        task.cancel()
        loader.failRequest(with: CancellationError())
        await task.value

        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
        #expect(loader.resultStates == [.cancelled])
    }

    @Test
    func loadEntries_doesNotDeliverErrorMessageOnLoaderCancellation() async {
        let (sut, loader, _) = makeSUT()

        await loader.failRequest(with: CancellationError()) { await sut.loadEntries() }

        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
        #expect(loader.resultStates == [.cancelled])
    }

    @Test
    func loadEntries_doesNotRequestLoaderAgainWhileLoading() async {
        let (sut, loader, _) = makeSUT()

        let firstTask = Task { await sut.loadEntries() }
        await loader.waitForRequest()

        await sut.loadEntries()

        #expect(loader.requests.count == 1)

        loader.completeRequest(with: [])
        await firstTask.value
    }

    @Test
    func loadEntries_deliversLoadedEntriesOnLoaderSuccess() async {
        let calendar = Calendar(identifier: .gregorian)
        let currentDate = Date(timeIntervalSince1970: 1000)
        let (sut, loader, _) = makeSUT(
            currentDate: { currentDate },
            calendar: calendar
        )
        let entry = anyEntry(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            text: anyText(),
            imageURL: anyImageURL(),
            audioURL: anyAudioURL(),
            createdAt: currentDate.adding(minutes: -5, calendar: calendar)
        )

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }

        #expect(sut.entries == [
            EntryDTO(
                id: entry.id,
                text: entry.text,
                imageURL: entry.imageURL,
                audioURL: entry.audioURL,
                timestamp: "5 minutes ago"
            )
        ])
    }

    @Test
    func loadEntries_deliversEntriesInOrderProvidedByLoader() async {
        let (sut, loader, _) = makeSUT()
        let entry1 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        let entry2 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!)
        let entry3 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!)

        await loader.completeRequest(with: [entry1, entry2, entry3]) { await sut.loadEntries() }

        #expect(sut.entries.map(\.id) == [entry1.id, entry2.id, entry3.id])
    }

    @Test
    func loadEntries_replacesLoadedEntriesWithEmptyListOnEmptyLoaderResult() async {
        let (sut, loader, _) = makeSUT()
        let entry = anyEntry()

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }
        await loader.completeRequest(with: [], at: 1) { await sut.loadEntries() }

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

        await loader.completeRequest(with: samples.map { $0.entry }) { await sut.loadEntries() }

        #expect(sut.entries.map(\.timestamp) == samples.map { $0.timestamp })
    }

    @Test
    func loadEntries_deliversErrorMessageOnLoaderFailure() async {
        let (sut, loader, _) = makeSUT()

        await loader.failRequest { await sut.loadEntries() }

        #expect(sut.errorMessage == EntryListViewModel.loadErrorMessage)
    }

    @Test
    func loadEntries_preservesPreviouslyLoadedEntriesOnFailure() async {
        let (sut, loader, _) = makeSUT()
        let entry = anyEntry()

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }
        let previouslyLoadedEntries = sut.entries

        await loader.failRequest(at: 1) { await sut.loadEntries() }

        #expect(sut.entries == previouslyLoadedEntries)
    }

    @Test
    func loadEntries_preservesPreviouslyLoadedEntriesWhileLoading() async {
        let (sut, loader, _) = makeSUT()
        let entry = anyEntry()

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }
        let previouslyLoadedEntries = sut.entries

        let retryLoad = Task { await sut.loadEntries() }
        await loader.waitForRequest(at: 1)

        #expect(sut.entries == previouslyLoadedEntries)

        loader.completeRequest(with: [], at: 1)
        await retryLoad.value
    }

    @Test
    func loadEntries_doesNotRestoreDeletedEntriesFromStaleLoaderResult() async {
        let (sut, loader, deleter) = makeSUT()
        let entry = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }

        let staleLoad = Task { await sut.loadEntries() }
        await loader.waitForRequest(at: 1)

        await deleter.completeRequest { await sut.delete(entry.id) }

        loader.completeRequest(with: [entry], at: 1)
        await staleLoad.value

        #expect(sut.entries.isEmpty)
    }

    @Test
    func loadEntries_clearsErrorMessageOnRetry() async {
        let (sut, loader, _) = makeSUT()

        await loader.failRequest { await sut.loadEntries() }

        let retryLoad = Task { await sut.loadEntries() }
        await loader.waitForRequest(at: 1)

        #expect(sut.errorMessage == nil)

        loader.completeRequest(with: [], at: 1)
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

        await deleter.completeRequest { await sut.delete(id) }

        #expect(deleter.params == [id])
    }

    @Test
    func delete_removesEntryFromListOnSuccess() async {
        let (sut, loader, deleter) = makeSUT()
        let entry1 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        let entry2 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!)

        await loader.completeRequest(with: [entry1, entry2]) { await sut.loadEntries() }
        await deleter.completeRequest { await sut.delete(entry1.id) }

        #expect(sut.entries.map(\.id) == [entry2.id])
    }

    @Test
    func delete_preservesEntriesWhenDeletedEntryIsNotLoaded() async {
        let (sut, loader, deleter) = makeSUT()
        let entry = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }
        let loadedEntries = sut.entries

        await deleter.completeRequest { await sut.delete(anyEntryID()) }

        #expect(sut.entries == loadedEntries)
    }

    @Test
    func delete_preservesEntriesOnFailure() async {
        let (sut, loader, deleter) = makeSUT()
        let entry1 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)
        let entry2 = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!)

        await loader.completeRequest(with: [entry1, entry2]) { await sut.loadEntries() }
        let loadedEntries = sut.entries

        await deleter.failRequest { await sut.delete(entry1.id) }

        #expect(sut.entries == loadedEntries)
    }

    @Test
    func delete_deliversErrorMessageOnDeletionFailure() async {
        let (sut, _, deleter) = makeSUT()

        await deleter.failRequest { await sut.delete(anyEntryID()) }

        #expect(sut.errorMessage == EntryListViewModel.deleteErrorMessage)
    }

    @Test
    func delete_doesNotDeliverErrorMessageOnCancellation() async {
        let (sut, _, deleter) = makeSUT()

        let task = Task { await sut.delete(anyEntryID()) }
        await deleter.waitForRequest()

        task.cancel()
        deleter.failRequest(with: CancellationError())
        await task.value

        #expect(sut.errorMessage == nil)
        #expect(deleter.resultStates == [.cancelled])
    }

    @Test
    func delete_doesNotDeliverErrorMessageOnDeletionCancellation() async {
        let (sut, _, deleter) = makeSUT()

        await deleter.failRequest(with: CancellationError()) { await sut.delete(anyEntryID()) }

        #expect(sut.errorMessage == nil)
        #expect(deleter.resultStates == [.cancelled])
    }

    @Test
    func delete_preservesEntriesOnCancellation() async {
        let (sut, loader, deleter) = makeSUT()
        let entry = anyEntry(id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!)

        await loader.completeRequest(with: [entry]) { await sut.loadEntries() }
        let loadedEntries = sut.entries

        await deleter.failRequest(with: CancellationError()) { await sut.delete(entry.id) }

        #expect(sut.entries == loadedEntries)
    }

    @Test
    func delete_clearsErrorMessageOnRetry() async {
        let (sut, _, deleter) = makeSUT()
        let id = anyEntryID()

        await deleter.failRequest { await sut.delete(id) }

        let retryDeletion = Task { await sut.delete(id) }
        await deleter.waitForRequest(at: 1)

        #expect(sut.errorMessage == nil)

        deleter.completeRequest(at: 1)
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
            loader: loader.load,
            delete: deleter.load,
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
