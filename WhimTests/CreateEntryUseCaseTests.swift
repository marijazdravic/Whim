import Foundation
import Testing
import Whim


struct CreateEntryUseCaseTests {
    @Test
    func init_doesNotRequestStoreInsertion() {
        let (_, store) = makeSUT()
        #expect(store.insertedEntries.isEmpty)
    }
    
    @Test
    func createEntry_throwsInvalidInputErrorOnEmptyInput() {
        let (sut, store) = makeSUT()
        #expect(throws: EntryCreator.Error.invalidInput) {
            try sut.createEntry(from: emptyInput())
        }
        #expect(store.insertedEntries.isEmpty)
    }

    @Test
    func createEntry_throwsInvalidInputErrorOnVariousWhitespaceOnlyInputs() {
        let (sut, store) = makeSUT()

        let whitespaceOnlyInputs = [
            CreateEntryInput(text: "   ", imageURL: nil, audioURL: nil),
            CreateEntryInput(text: "\t", imageURL: nil, audioURL: nil),
            CreateEntryInput(text: "\n", imageURL: nil, audioURL: nil),
            CreateEntryInput(text: " \t\n ", imageURL: nil, audioURL: nil),
            CreateEntryInput(text: "\r\n", imageURL: nil, audioURL: nil),
        ]

        for input in whitespaceOnlyInputs {
            #expect(throws: EntryCreator.Error.invalidInput) {
                try sut.createEntry(from: input)
            }
        }

        #expect(store.insertedEntries.isEmpty)
    }

    @Test
    func createEntry_throwsInvalidInputErrorWhenAllFieldsAreNil() {
        let (sut, store) = makeSUT()
        #expect(throws: EntryCreator.Error.invalidInput) {
            try sut.createEntry(
                from: CreateEntryInput(text: nil, imageURL: nil, audioURL: nil)
            )
        }
        #expect(store.insertedEntries.isEmpty)
    }

    @Test
    func createEntry_deliversErrorOnStoreInsertionFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        store.stub(expectedError)
        let input = anyTextInput()

        #expect(throws: expectedError) {
            try sut.createEntry(from: input)
        }

        #expect(store.insertedEntries.count == 1)
        #expect(store.insertedEntries.first?.text == input.text)
    }

    @Test
    func createEntry_insertsEntryWithTextOnlyInput() throws {
        let (sut, store) = makeSUT()
        let text = anyText()

        try sut.createEntry(
            from: CreateEntryInput(text: text, imageURL: nil, audioURL: nil)
        )

        let saved = try #require(store.insertedEntries.first)
        #expect(saved.text == text)
        #expect(saved.imageURL == nil)
        #expect(saved.audioURL == nil)
    }

    @Test
    func createEntry_insertsEntryWithImageURLOnlyInput() throws {
        let (sut, store) = makeSUT()
        let imageURL = anyImageURL()

        try sut.createEntry(
            from: CreateEntryInput(text: nil, imageURL: imageURL, audioURL: nil)
        )

        let saved = try #require(store.insertedEntries.first)
        #expect(saved.imageURL == imageURL)
        #expect(saved.text == nil)
        #expect(saved.audioURL == nil)
    }

    @Test
    func createEntry_insertsEntryWithAudioURLOnlyInput() throws {
        let (sut, store) = makeSUT()
        let audioURL = anyAudioURL()

        try sut.createEntry(
            from: CreateEntryInput(text: nil, imageURL: nil, audioURL: audioURL)
        )

        let saved = try #require(store.insertedEntries.first)
        #expect(saved.audioURL == audioURL)
        #expect(saved.text == nil)
        #expect(saved.imageURL == nil)
    }

    @Test
    func createEntry_insertsEntryWithAllFieldsPresent() throws {
        let (sut, store) = makeSUT()
        let text = anyText()
        let imageURL = anyImageURL()
        let audioURL = anyAudioURL()

        try sut.createEntry(
            from: CreateEntryInput(
                text: text,
                imageURL: imageURL,
                audioURL: audioURL
            )
        )

        let saved = try #require(store.insertedEntries.first)
        #expect(saved.text == text)
        #expect(saved.imageURL == imageURL)
        #expect(saved.audioURL == audioURL)
        #expect(saved.status == .draft)
    }

    @Test
    func createEntry_createsEntryWithGeneratedIDAndCreationDate() throws {
        let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let fixedDate = Date(timeIntervalSince1970: 1598627222)

        let (sut, store) = makeSUT(
            idGenerator: { fixedID },
            dateGenerator: { fixedDate }
        )

        try sut.createEntry(from: anyTextInput())

        let saved = try #require(store.insertedEntries.first)
        #expect(saved.id == fixedID)
        #expect(saved.createdAt == fixedDate)
    }

    // MARK: - Helpers

    private func makeSUT(
        idGenerator: @escaping () -> UUID = UUID.init,
        dateGenerator: @escaping () -> Date = Date.init
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
        
        private(set) var insertedEntries = [Entry]()
        private var insertionError: Error?
        
        func insert(_ entry: Entry) throws {
            insertedEntries.append(entry)
            
            if let error = insertionError {
                throw error
            }
        }
        
        func stub(_ error: Swift.Error) {
            self.insertionError = error
        }
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
    
    private func anyTextInput() -> CreateEntryInput {
        CreateEntryInput(text: anyText(), imageURL: nil, audioURL: nil)
    }

    private func anyText() -> String {
        "Any text"
    }

    private func emptyInput() -> CreateEntryInput {
        CreateEntryInput(text: "", imageURL: nil, audioURL: nil)
    }
    
    private func anyAudioURL() -> URL {
        URL(string: "file:///some/audio.m4a")!
    }
    
    private func anyImageURL() -> URL {
        URL(string: "file:///some/image.jpg")!
    }
}
