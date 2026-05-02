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

    // MARK: - Helpers

    private func makeSUT() -> (sut: CaptureViewModel, creator: CreateEntrySpy) {
        let creator = CreateEntrySpy()
        let sut = CaptureViewModel(createEntry: creator.load)
        return (sut, creator)
    }
}
