import Foundation
import Testing
import Whim

private typealias CreateEntrySpy = AsyncLoaderSpy<CreateEntryInput, Void>

@MainActor
struct CaptureViewModelTests {
    @Test
    func init_doesNotRequestEntryCreation() {
        let (_, creator) = makeSUT()

        #expect(creator.requests.isEmpty)
    }

    @Test
    func saveText_requestsEntryCreationWithText() async {
        let (sut, creator) = makeSUT()
        let text = anyText()
        sut.text = text

        await creator.completeRequest { await sut.saveText() }

        #expect(creator.params == [
            CreateEntryInput(text: text, imageURL: nil, audioURL: nil)
        ])
        #expect(creator.resultStates == [.success])
    }

    @Test
    func saveText_setsSavingStateWhileCreatingEntry() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        let task = Task { await sut.saveText() }
        await creator.waitForRequest()

        #expect(sut.isSaving == true)

        creator.completeRequest()
        await task.value

        #expect(sut.isSaving == false)
    }

    @Test
    func saveText_clearsTextOnEntryCreationSuccess() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.completeRequest { await sut.saveText() }

        #expect(sut.text.isEmpty)
    }

    @Test
    func saveText_deliversErrorMessageOnEntryCreationFailure() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.failRequest { await sut.saveText() }

        #expect(sut.errorMessage == CaptureViewModel.saveErrorMessage)
    }

    @Test
    func saveText_preservesTextOnEntryCreationFailure() async {
        let (sut, creator) = makeSUT()
        let text = anyText()
        sut.text = text

        await creator.failRequest { await sut.saveText() }

        #expect(sut.text == text)
    }

    @Test
    func saveText_clearsErrorMessageOnRetry() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.failRequest { await sut.saveText() }

        let retrySave = Task { await sut.saveText() }
        await creator.waitForRequest(at: 1)

        #expect(sut.errorMessage == nil)

        creator.completeRequest(at: 1)
        await retrySave.value
    }

    @Test
    func saveText_doesNotDeliverErrorMessageOnCancellation() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        let task = Task { await sut.saveText() }
        await creator.waitForRequest()

        task.cancel()
        creator.failRequest(with: CancellationError())
        await task.value

        #expect(sut.errorMessage == nil)
        #expect(sut.isSaving == false)
        #expect(creator.resultStates == [.cancelled])
    }

    @Test
    func saveText_doesNotDeliverErrorMessageOnEntryCreationCancellation() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.failRequest(with: CancellationError()) { await sut.saveText() }

        #expect(sut.errorMessage == nil)
        #expect(sut.isSaving == false)
        #expect(creator.resultStates == [.cancelled])
    }

    @Test
    func saveText_preservesTextOnCancellation() async {
        let (sut, creator) = makeSUT()
        let text = anyText()
        sut.text = text

        let task = Task { await sut.saveText() }
        await creator.waitForRequest()

        task.cancel()
        creator.failRequest(with: CancellationError())
        await task.value

        #expect(sut.text == text)
    }

    @Test
    func saveText_doesNotRequestEntryCreationWhenAlreadySaving() async {
        let creator = EntryCreationWhileSavingSpy()
        let sut = CaptureViewModel(createEntry: creator.create)
        let text = anyText()
        sut.text = text

        let firstSave = Task { await sut.saveText() }
        await creator.waitForRequest()

        await sut.saveText()

        #expect(creator.requests == [
            CreateEntryInput(text: text, imageURL: nil, audioURL: nil)
        ])

        creator.completeFirstRequest()
        await firstSave.value
    }

    @Test
    func saveErrorMessage_isLocalized() {
        #expect(CaptureViewModel.saveErrorMessage == localized("CAPTURE_SAVE_ERROR"))
    }

    @Test
    func discardDraft_clearsText() {
        let (sut, _) = makeSUT()
        sut.text = anyText()

        sut.discardDraft()

        #expect(sut.text.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: CaptureViewModel, creator: CreateEntrySpy) {
        let creator = CreateEntrySpy()
        let sut = CaptureViewModel(createEntry: creator.load)
        return (sut, creator)
    }

    private func localized(_ key: String) -> String {
        let table = "Capture"
        let value = Bundle(for: CaptureViewModel.self).localizedString(
            forKey: key,
            value: nil,
            table: table
        )

        #expect(value != key, "Missing localized string for key: \(key) in table: \(table)")

        return value
    }
}

@MainActor
private final class EntryCreationWhileSavingSpy {
    private(set) var requests = [CreateEntryInput]()
    private var firstRequestContinuation: CheckedContinuation<Void, Error>?
    private var requestWaiters = [CheckedContinuation<Void, Never>]()

    func create(_ input: CreateEntryInput) async throws {
        requests.append(input)
        completeRequestWaiters()

        guard requests.count == 1 else { return }

        try await withCheckedThrowingContinuation { continuation in
            firstRequestContinuation = continuation
        }
    }

    func waitForRequest() async {
        guard requests.isEmpty else { return }

        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func completeFirstRequest() {
        firstRequestContinuation?.resume(returning: ())
        firstRequestContinuation = nil
    }

    private func completeRequestWaiters() {
        requestWaiters.forEach { $0.resume() }
        requestWaiters.removeAll()
    }
}
