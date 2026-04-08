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
    func createEntry_requestsStoreToInsertEntryOnValidInput() throws {
        let (sut, store) = makeSUT()
        let input = anyTextInput()
        
        try sut.createEntry(from: input)
        
        #expect(store.insertedEntries.count == 1)
        #expect(store.insertedEntries.first?.text == input.text)
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
    func createEntry_throwsInvalidInputErrorOnVariousWhitespaceOnlyInputs() {
        let (sut, store) = makeSUT()
        
        let whitespaceOnlyInputs = [
            CreateEntryInput(text: "   "),
            CreateEntryInput(text: "\t"),
            CreateEntryInput(text: "\n"),
            CreateEntryInput(text: " \t\n "),
            CreateEntryInput(text: "\r\n")
        ]
        
        for input in whitespaceOnlyInputs {
            #expect(throws: EntryCreator.Error.invalidInput) {
                try sut.createEntry(from: input)
            }
        }
        
        #expect(store.insertedEntries.isEmpty)
    }
    
    @Test
    func createEntry_createsEntryFromInputWithGeneratedIDAndCreationDate() throws {
        let fixedID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let fixedDate = Date(timeIntervalSince1970: 1598627222)
        let input = anyTextInput()
        
        let (sut, store) = makeSUT(
            idGenerator: { fixedID },
            dateGenerator: { fixedDate }
        )
        
        try sut.createEntry(from: input)
        
        let savedEntry = try #require(store.insertedEntries.first)
        #expect(savedEntry.id == fixedID)
        #expect(savedEntry.text == input.text)
        #expect(savedEntry.createdAt == fixedDate)
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
        CreateEntryInput(text: "Any text")
    }
    
    private func emptyInput() -> CreateEntryInput {
        CreateEntryInput(text: "")
    }
}
