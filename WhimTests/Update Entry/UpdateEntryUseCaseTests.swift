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
        let existing = anyEntry(id: id, imageURL: nil, audioURL: nil)
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
        let existing = anyEntry(text: anyText())
        let expected = existing.with(text: updatedText())
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
        let existing = anyEntry(text: anyText())
        let expected = existing.with(text: nil)
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
        let existing = anyEntry(imageURL: nil)
        let expected = existing.with(imageURL: newImageURL)
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
        let existing = anyEntry()
        let expected = existing.with(imageURL: nil)
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
        let existing = anyEntry(audioURL: nil)
        let expected = existing.with(audioURL: newAudioURL)
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
        let existing = anyEntry()
        let expected = existing.with(audioURL: nil)
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
        let existing = anyEntry(text: anyText())
        let expected = existing.with(text: updatedText())
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
        let existing = anyEntry(text: anyText())
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
        let existing = anyEntry(imageURL: nil, audioURL: nil)
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
        let existing = anyEntry(text: anyText())
        let expected = existing.with(text: nil)
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
            (.clearText, anyEntry(imageURL: nil, audioURL: nil)),
            (.clearImage, anyEntry(text: nil, audioURL: nil)),
            (.clearAudio, anyEntry(text: nil, imageURL: nil)),
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
        let existing = anyEntry(text: whitespaceOnlyText(), audioURL: nil)
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
}

private extension Entry {
    func with(text: String?) -> Entry {
        Entry(
            id: id,
            text: text,
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )
    }

    func with(imageURL: URL?) -> Entry {
        Entry(
            id: id,
            text: text,
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )
    }

    func with(audioURL: URL?) -> Entry {
        Entry(
            id: id,
            text: text,
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: createdAt
        )
    }
}
