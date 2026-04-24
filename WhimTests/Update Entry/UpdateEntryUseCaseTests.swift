import Foundation
import Testing
import Whim

struct EntryUpdaterTests {
    @Test
    func init_doesNotRequestStoreMessages() {
        let (_, store) = makeSUT()

        #expect(store.receivedMessages.isEmpty)
    }

    @Test
    func apply_requestsStoreToRetrieveEntryByID() throws {
        let (sut, store) = makeSUT()
        let id = UUID()
        let existing = Entry(
            id: id,
            text: anyText(),
            imageURL: nil,
            audioURL: nil,
            createdAt: anyEntryDate()
        )
        store.stubRetrieval(with: existing)

        _ = try sut.apply(.setText(updatedText()), to: id)

        #expect(store.receivedMessages.first == .retrieve(id))
    }

    @Test
    func
        apply_deliversNotFoundErrorWithoutRequestingStoreUpdateWhenEntryDoesNotExist()
    {
        let (sut, store) = makeSUT()
        let id = UUID()

        #expect(throws: EntryUpdater.Error.notFound) {
            try sut.apply(.setText(anyText()), to: id)
        }

        #expect(store.receivedMessages == [.retrieve(id)])
    }

    @Test
    func apply_setText_updatesTextPreservingIDCreatedAtAndOtherFields() throws {
        let (sut, store) = makeSUT()
        let (existing, expected) = anyEntries(
            existingText: anyText(),
            expectedText: updatedText()
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.setText(updatedText()), to: existing.id)
            }
        )
    }

    @Test
    func apply_clearText_clearsTextPreservingIDCreatedAtAndOtherFields() throws
    {
        let (sut, store) = makeSUT()
        let (existing, expected) = anyEntries(
            existingText: anyText(),
            expectedText: nil
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.clearText, to: existing.id)
            }
        )
    }

    @Test
    func apply_setImage_updatesImageURLPreservingIDCreatedAtAndOtherFields()
        throws
    {
        let (sut, store) = makeSUT()
        let newImageURL = anyImageURL()
        let (existing, expected) = anyEntries(
            existingImageURL: nil,
            expectedImageURL: newImageURL
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.setImage(newImageURL), to: existing.id)
            }
        )
    }

    @Test
    func apply_clearImage_clearsImageURLPreservingIDCreatedAtAndOtherFields()
        throws
    {
        let (sut, store) = makeSUT()
        let (existing, expected) = anyEntries(
            existingImageURL: anyImageURL(),
            expectedImageURL: nil
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.clearImage, to: existing.id)
            }
        )
    }

    @Test
    func apply_setAudio_updatesAudioURLPreservingIDCreatedAtAndOtherFields()
        throws
    {
        let (sut, store) = makeSUT()
        let newAudioURL = anyAudioURL()
        let (existing, expected) = anyEntries(
            existingAudioURL: nil,
            expectedAudioURL: newAudioURL
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.setAudio(newAudioURL), to: existing.id)
            }
        )
    }

    @Test
    func apply_clearAudio_clearsAudioURLPreservingIDCreatedAtAndOtherFields()
        throws
    {
        let (sut, store) = makeSUT()
        let (existing, expected) = anyEntries(
            existingAudioURL: anyAudioURL(),
            expectedAudioURL: nil
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.clearAudio, to: existing.id)
            }
        )
    }

    @Test
    func apply_deliversErrorOnStoreRetrievalFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        let id = anyEntryID()
        store.stubRetrieval(with: expectedError)

        #expect(throws: expectedError) {
            _ = try sut.apply(.setText(anyText()), to: id)
        }

        #expect(store.receivedMessages == [.retrieve(id)])
    }

    @Test
    func apply_deliversErrorOnStoreUpdateFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyNSError()
        let (existing, expected) = anyEntries(
            existingText: anyText(),
            expectedText: updatedText()
        )
        store.stubRetrieval(with: existing)
        store.stubUpdate(with: expectedError)

        #expect(throws: expectedError) {
            _ = try sut.apply(.setText(updatedText()), to: existing.id)
        }

        #expect(
            store.receivedMessages == [
                .retrieve(existing.id),
                .update(expected),
            ]
        )
    }

    @Test
    func apply_mapsStoreNotFoundErrorToEntryUpdaterNotFound() {
        let (sut, store) = makeSUT()
        let (existing, _) = anyEntries(
            existingText: anyText(),
            expectedText: updatedText()
        )
        store.stubRetrieval(with: existing)
        store.stubUpdate(with: EntryStoreError.notFound)

        #expect(throws: EntryUpdater.Error.notFound) {
            _ = try sut.apply(.setText(updatedText()), to: existing.id)
        }
    }

    @Test
    func
        apply_setTextWithWhitespaceOnlyText_deliversDeleteConfirmationWhenEntryHasNoOtherContent()
        throws
    {
        let (sut, store) = makeSUT()
        let existing = Entry(
            id: anyEntryID(),
            text: anyText(),
            imageURL: nil,
            audioURL: nil,
            createdAt: anyEntryDate()
        )
        store.stubRetrieval(with: existing)

        let result = try sut.apply(.setText(whitespaceOnlyText()), to: existing.id)

        #expect(result == .requiresDeleteConfirmation)
        #expect(store.receivedMessages == [.retrieve(existing.id)])
    }

    @Test
    func apply_setTextWithWhitespaceOnlyText_clearsTextPreservingOtherContent()
        throws
    {
        let (sut, store) = makeSUT()
        let imageURL = anyImageURL()
        let (existing, expected) = anyEntries(
            existingText: anyText(),
            expectedText: nil,
            existingImageURL: imageURL,
            expectedImageURL: imageURL
        )
        store.stubRetrieval(with: existing)

        try expect(
            toSend: [.retrieve(existing.id), .update(expected)],
            to: store,
            when: {
                _ = try sut.apply(.setText(whitespaceOnlyText()), to: existing.id)
            }
        )
    }
    @Test
    func apply_deliversDeleteConfirmationWhenClearingLastContent() throws {
        let scenarios: [(update: EntryUpdate, existing: Entry)] = [
            (
                .clearText,
                Entry(
                    id: anyEntryID(),
                    text: anyText(),
                    imageURL: nil,
                    audioURL: nil,
                    createdAt: anyEntryDate()
                )
            ),
            (
                .clearImage,
                Entry(
                    id: anyEntryID(),
                    text: nil,
                    imageURL: anyImageURL(),
                    audioURL: nil,
                    createdAt: anyEntryDate()
                )
            ),
            (
                .clearAudio,
                Entry(
                    id: anyEntryID(),
                    text: nil,
                    imageURL: nil,
                    audioURL: anyAudioURL(),
                    createdAt: anyEntryDate()
                )
            ),
        ]

        for scenario in scenarios {
            let (sut, store) = makeSUT()
            store.stubRetrieval(with: scenario.existing)

            let result = try sut.apply(
                scenario.update,
                to: scenario.existing.id
            )

            #expect(result == .requiresDeleteConfirmation)
            #expect(store.receivedMessages == [.retrieve(scenario.existing.id)])
        }
    }

    @Test
    func apply_clearImage_deliversDeleteConfirmationWhenRemainingTextIsWhitespaceOnly()
        throws
    {
        let (sut, store) = makeSUT()
        let existing = Entry(
            id: anyEntryID(),
            text: whitespaceOnlyText(),
            imageURL: anyImageURL(),
            audioURL: nil,
            createdAt: anyEntryDate()
        )
        store.stubRetrieval(with: existing)

        let result = try sut.apply(.clearImage, to: existing.id)

        #expect(result == .requiresDeleteConfirmation)
        #expect(store.receivedMessages == [.retrieve(existing.id)])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: EntryUpdater, store: EntryStoreSpy) {
        let store = EntryStoreSpy()
        let sut = EntryUpdater(store: store)
        return (sut, store)
    }

    private func expect(
        toSend expectedMessages: [EntryStoreSpy.ReceivedMessage],
        to store: EntryStoreSpy,
        when action: () throws -> Void,
        sourceLocation: SourceLocation = #_sourceLocation
    ) rethrows {
        try action()

        #expect(
            store.receivedMessages == expectedMessages,
            sourceLocation: sourceLocation
        )
    }

    private func anyEntries(
        id: UUID = anyEntryID(),
        existingText: String? = anyText(),
        expectedText: String? = anyText(),
        existingImageURL: URL? = anyImageURL(),
        expectedImageURL: URL? = anyImageURL(),
        existingAudioURL: URL? = anyAudioURL(),
        expectedAudioURL: URL? = anyAudioURL(),
        createdAt: Date = anyEntryDate()
    ) -> (existing: Entry, expected: Entry) {
        (
            existing: Entry(
                id: id,
                text: existingText,
                imageURL: existingImageURL,
                audioURL: existingAudioURL,
                createdAt: createdAt
            ),
            expected: Entry(
                id: id,
                text: expectedText,
                imageURL: expectedImageURL,
                audioURL: expectedAudioURL,
                createdAt: createdAt
            )
        )
    }
}
