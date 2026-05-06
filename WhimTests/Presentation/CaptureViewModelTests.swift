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
    func init_hasNoDraftAndCannotSaveText() {
        let (sut, _) = makeSUT()

        #expect(sut.hasDraft == false)
        #expect(sut.canSaveText == false)
    }

    @Test
    func textWithContent_hasDraftAndCanSaveText() {
        let (sut, _) = makeSUT()

        sut.text = anyText()

        #expect(sut.hasDraft == true)
        #expect(sut.canSaveText == true)
    }

    @Test(arguments: [
        "",
        " ",
        "   ",
        "\t",
        "\n",
        " \t\n ",
        "\r\n",
    ])
    func textWithoutContent_hasNoDraftAndCannotSaveText(_ text: String) {
        let (sut, _) = makeSUT()

        sut.text = text

        #expect(sut.hasDraft == false)
        #expect(sut.canSaveText == false)
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
        #expect(sut.canSaveText == false)

        creator.completeRequest()
        await task.value

        #expect(sut.isSaving == false)
    }

    @Test(arguments: [
        "",
        " ",
        "   ",
        "\t",
        "\n",
        " \t\n ",
        "\r\n",
    ])
    func saveText_doesNotRequestEntryCreationForTextWithoutContent(_ text: String) async {
        let (sut, creator) = makeSUT()
        sut.text = text

        await sut.saveText()

        #expect(creator.requests.isEmpty)
        #expect(sut.isSaving == false)
        #expect(sut.errorMessage == nil)
    }

    @Test
    func saveText_clearsTextOnEntryCreationSuccess() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.completeRequest { await sut.saveText() }

        #expect(sut.text.isEmpty)
    }

    @Test
    func saveText_doesNotClearTextChangedWhileCreatingEntryOnSuccess() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        let task = Task { await sut.saveText() }
        await creator.waitForRequest()

        sut.text = updatedText()

        creator.completeRequest()
        await task.value

        #expect(sut.text == updatedText())
    }

    @Test
    func saveText_deliversErrorMessageOnEntryCreationFailure() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.failRequest { await sut.saveText() }

        #expect(sut.errorMessage == CaptureViewModel.saveErrorMessage)
    }

    @Test
    func saveText_doesNotDeliverErrorMessageWhenTextChangedWhileCreatingEntryFails() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        let task = Task { await sut.saveText() }
        await creator.waitForRequest()

        sut.text = updatedText()

        creator.failRequest()
        await task.value

        #expect(sut.errorMessage == nil)
        #expect(sut.text == updatedText())
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
        let (sut, creator) = makeSUT()
        let text = anyText()
        sut.text = text

        let firstSave = Task { await sut.saveText() }
        await creator.waitForRequest()

        await sut.saveText()

        #expect(creator.params == [
            CreateEntryInput(text: text, imageURL: nil, audioURL: nil)
        ])

        creator.completeRequest()
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

    @Test
    func discardDraft_clearsErrorMessage() async {
        let (sut, creator) = makeSUT()
        sut.text = anyText()

        await creator.failRequest { await sut.saveText() }

        #expect(sut.errorMessage == CaptureViewModel.saveErrorMessage)

        sut.discardDraft()

        #expect(sut.errorMessage == nil)
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
