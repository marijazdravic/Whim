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
        CreateEntryInput(text: Self.anyText(), imageURL: nil, audioURL: nil),
        CreateEntryInput(text: nil, imageURL: Self.anyImageURL(), audioURL: nil),
        CreateEntryInput(text: nil, imageURL: nil, audioURL: Self.anyAudioURL()),
        CreateEntryInput(
            text: Self.anyText(),
            imageURL: Self.anyImageURL(),
            audioURL: Self.anyAudioURL()
        )
    ])
    func createEntry_insertsEntryForValidInput(_ input: CreateEntryInput) throws {
        let (sut, store) = makeSUT()

        try sut.createEntry(from: input)

        let insertedEntry = try #require(store.insertedEntry)

        #expect(insertedEntry.text == input.text)
        #expect(insertedEntry.imageURL == input.imageURL)
        #expect(insertedEntry.audioURL == input.audioURL)
        #expect(insertedEntry.status == .draft)
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
                    text: Self.anyText(),
                    imageURL: nil,
                    audioURL: nil,
                    createdAt: fixedDate,
                    status: .draft
                )
            )
        ])
    }

    // MARK: - Helpers
    
    private let anyEntryID = UUID(
        uuidString: "11111111-1111-1111-1111-111111111111"
    )!

    private let anyEntryDate = Date(timeIntervalSince1970: 1_598_627_222)


    private func makeSUT(
        idGenerator: @escaping () -> UUID = { anyEntryID },
        dateGenerator: @escaping () -> Date = { anyEntryDate }
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

    private final class EntryStoreSpy: EntryStore {

        enum ReceivedMessage: Equatable {
            case insert(Entry)
        }

        private(set) var receivedMessages = [ReceivedMessage]()
        private var insertionResult: Result<Void, Error>?

        var insertedEntry: Entry? {
            guard case let .insert(entry)? = receivedMessages.first else { return nil }
            return entry
        }

        func insert(_ entry: Entry) throws {
            receivedMessages.append(.insert(entry))
            try insertionResult?.get()
        }

        func stubInsertionToFail(_ error: Swift.Error) {
            self.insertionResult = .failure(error)
        }
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private func anyTextInput() -> CreateEntryInput {
        CreateEntryInput(text: Self.anyText(), imageURL: nil, audioURL: nil)
    }

    private static func anyText() -> String {
        "Any text"
    }

    private static func anyAudioURL() -> URL {
        URL(string: "file:///some/audio.m4a")!
    }

    private static func anyImageURL() -> URL {
        URL(string: "file:///some/image.jpg")!
    }
}
