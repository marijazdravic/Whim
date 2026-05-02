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
    func saveText_doesNotRequestEntryCreationWhenAlreadySaving() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        let firstSave = Task { await sut.saveText() }
        await creator.waitForRequest()

        let secondSave = Task { await sut.saveText() }
        await Task.yield()

        #expect(creator.requests.count == 1)

        creator.completeRequest()
        if creator.requests.indices.contains(1) {
            creator.completeRequest(at: 1)
        }

        await firstSave.value
        await secondSave.value
    }

    @Test
    func saveErrorMessage_isLocalized() {
        #expect(CaptureViewModel.saveErrorMessage == localized("CAPTURE_SAVE_ERROR"))
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
