//
//  EntryUpdater.swift
//  Whim
//
//  Created by Marija Zdravic on 20.04.2026..
//

import Foundation

public enum EntryUpdate {
    case setText(String)
    case clearText
    case setImage(URL)
    case clearImage
    case setAudio(URL)
    case clearAudio
}

public final class EntryUpdater {
    public enum Error: Swift.Error, Equatable {
        case notFound
    }

    public enum ApplyOutcome: Equatable {
        case requiresDeleteConfirmation
    }

    private let store: EntryStore

    public init(store: EntryStore) {
        self.store = store
    }

    public func apply(_ update: EntryUpdate, to id: UUID) throws -> ApplyOutcome? {
        guard let entry = try store.retrieve(by: id) else {
            throw Error.notFound
        }

        let updatedEntry = makeUpdatedEntry(byApplying: update, to: entry)

        if let outcome = try validateOutcome(for: updatedEntry) {
            return outcome
        }

        try updateStore(with: updatedEntry)
        return nil
    }
}

private extension EntryUpdater {
    private func makeUpdatedEntry(byApplying update: EntryUpdate, to entry: Entry) -> Entry {
        Entry(
            id: entry.id,
            text: updatedText(for: update, currentText: entry.text),
            imageURL: updatedImageURL(for: update, currentImageURL: entry.imageURL),
            audioURL: updatedAudioURL(for: update, currentAudioURL: entry.audioURL),
            createdAt: entry.createdAt
        )
    }

    private func validateOutcome(for entry: Entry) throws -> ApplyOutcome? {
        do {
            try entry.validate()
            return nil
        } catch Entry.ValidationError.missingContent {
            return .requiresDeleteConfirmation
        }
    }

    private func updateStore(with entry: Entry) throws {
        do {
            try store.update(entry)
        } catch EntryStoreError.notFound {
            throw Error.notFound
        }
    }

    private func updatedText(for update: EntryUpdate, currentText: String?) -> String? {
        switch update {
        case .setText(let value):
            return Entry.nonEmptyText(value)
        case .clearText:
            return nil
        default:
            return currentText
        }
    }

    private func updatedImageURL(for update: EntryUpdate, currentImageURL: URL?) -> URL? {
        switch update {
        case .setImage(let value):
            return value
        case .clearImage:
            return nil
        default:
            return currentImageURL
        }
    }

    private func updatedAudioURL(for update: EntryUpdate, currentAudioURL: URL?) -> URL? {
        switch update {
        case .setAudio(let value):
            return value
        case .clearAudio:
            return nil
        default:
            return currentAudioURL
        }
    }
}
