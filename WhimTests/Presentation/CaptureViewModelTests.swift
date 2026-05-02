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

    // MARK: - Helpers

    private func makeSUT() -> (sut: CaptureViewModel, creator: CreateEntrySpy) {
        let creator = CreateEntrySpy()
        let sut = CaptureViewModel(createEntry: creator.load)
        return (sut, creator)
    }
}
