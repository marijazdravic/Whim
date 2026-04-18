import Foundation
import Testing
import Whim

struct EntryCreatorTests {
    @Test
    func init_doesNotRequestStoreInsertion() {
        let (_, store) = makeSUT()
        #expect(store.receivedMessages == [])
    }

    @Test(arguments: [
        CreateEntryInput(text: "", imageURL: nil, audioURL: nil),
        CreateEntryInput(text: "   ", imageURL: nil, audioURL: nil),
        CreateEntryInput(text: "\t", imageURL: nil, audioURL: nil),
        CreateEntryInput(text: "\n", imageURL: nil, audioURL: nil),
        CreateEntryInput(text: " \t\n ", imageURL: nil, audioURL: nil),
        CreateEntryInput(text: "\r\n", imageURL: nil, audioURL: nil),
    ])
    func createEntry_throwsInvalidInputErrorOnTextWithoutContent(
        _ input: CreateEntryInput
    ) {
        let (sut, store) = makeSUT()

        #expect(throws: EntryCreator.Error.invalidInput) {
            try sut.createEntry(from: input)
        }

        #expect(store.receivedMessages == [])
    }

    @Test
    func createEntry_throwsInvalidInputErrorWhenAllFieldsAreNil() {
        let (sut, store) = makeSUT()
        #expect(throws: EntryCreator.Error.invalidInput) {
            try sut.createEntry(
                from: CreateEntryInput(text: nil, imageURL: nil, audioURL: nil)
            )
        }
        #expect(store.receivedMessages == [])
    }

    @Test
    func createEntry_deliversErrorOnStoreInsertionFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        let input = anyTextInput()

        store.stubInsertionToFail(expectedError)

        #expect(throws: expectedError) {
            try sut.createEntry(from: input)
        }

        let insertedEntry = store.insertedEntry
        #expect(insertedEntry?.text == input.text)
    }

    @Test(arguments: [
        CreateEntryInput(text: anyText(), imageURL: nil, audioURL: nil),
        CreateEntryInput(text: nil, imageURL: anyImageURL(), audioURL: nil),
        CreateEntryInput(text: nil, imageURL: nil, audioURL: anyAudioURL()),
        CreateEntryInput(
            text: anyText(),
            imageURL: anyImageURL(),
            audioURL: anyAudioURL()
        )
    ])
    func createEntry_insertsEntryForValidInput(_ input: CreateEntryInput) throws {
        let (sut, store) = makeSUT()

        try sut.createEntry(from: input)

        let insertedEntry = try #require(store.insertedEntry)

        #expect(insertedEntry.text == input.text)
        #expect(insertedEntry.imageURL == input.imageURL)
        #expect(insertedEntry.audioURL == input.audioURL)
    }

    @Test
    func createEntry_insertsEntryWithGeneratedIDAndCreationDate() throws {
        let fixedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let fixedDate = Date(timeIntervalSince1970: 0)

        let (sut, store) = makeSUT(
            idGenerator: { fixedID },
            dateGenerator: { fixedDate }
        )

        try sut.createEntry(from: anyTextInput())

        #expect(store.receivedMessages == [
            .insert(
                Entry(
                    id: fixedID,
                    text: anyText(),
                    imageURL: nil,
                    audioURL: nil,
                    createdAt: fixedDate
                )
            )
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        idGenerator: @escaping () -> UUID = { anyEntryID() },
        dateGenerator: @escaping () -> Date = { anyEntryDate() }
    ) -> (
        sut: EntryCreator,
        store: EntryStoreSpy
    ) {
        let store = EntryStoreSpy()
        let sut = EntryCreator(
            store: store,
            idGenerator: idGenerator,
            dateGenerator: dateGenerator
        )
        return (sut, store)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private func anyTextInput() -> CreateEntryInput {
        CreateEntryInput(text: anyText(), imageURL: nil, audioURL: nil)
    }
}
