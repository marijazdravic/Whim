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

    // MARK: - Helpers

    private func makeSUT() -> (sut: CaptureViewModel, creator: CreateEntrySpy) {
        let creator = CreateEntrySpy()
        let sut = CaptureViewModel(createEntry: creator.load)
        return (sut, creator)
    }
}
