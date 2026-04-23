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

        var text = entry.text
        var imageURL = entry.imageURL
        var audioURL = entry.audioURL

        apply(update, &text, &imageURL, &audioURL)

        let candidate = Entry(
            id: entry.id,
            text: text,
            imageURL: imageURL,
            audioURL: audioURL,
            createdAt: entry.createdAt
        )

        do {
            try candidate.validate()
        } catch Entry.ValidationError.missingContent {
            return .requiresDeleteConfirmation
        }

        do {
            try store.update(candidate)
        } catch EntryStoreError.notFound {
            throw Error.notFound
        }
        return nil
    }

    private func apply(
        _ update: EntryUpdate,
        _ text: inout String?,
        _ imageURL: inout URL?,
        _ audioURL: inout URL?
    ) {
        switch update {
        case .setText(let value): text = value.hasContent ? value : nil
        case .clearText: text = nil
        case .setImage(let value): imageURL = value
        case .clearImage: imageURL = nil
        case .setAudio(let value): audioURL = value
        case .clearAudio: audioURL = nil
        }
    }
}
