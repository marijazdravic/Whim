//
//  EntryListViewModel.swift
//  Whim
//
//  Created by Marija Zdravic on 28.04.2026..
//

import Foundation
import Observation

public typealias LoadEntries = () async throws -> [Entry]
public typealias DeleteEntry = (UUID) async throws -> Void

@MainActor
@Observable
public final class EntryListViewModel {
    private let loader: LoadEntries
    private let deleteEntry: DeleteEntry
    private let currentDate: () -> Date
    private let timestampFormatter: RelativeDateTimeFormatter
    private var deletedEntryIDs = Set<UUID>()
    
    public private(set) var entries = [EntryDTO]()
    public private(set) var errorMessage: String?
    public private(set) var isLoading = false
    public static let loadErrorMessage = NSLocalizedString(
        "ENTRY_LIST_LOAD_ERROR",
        tableName: "EntryList",
        bundle: Bundle(for: EntryListViewModel.self),
        comment: "Error message shown when loading entries fails"
    )
    public static let deleteErrorMessage = NSLocalizedString(
        "ENTRY_LIST_DELETE_ERROR",
        tableName: "EntryList",
        bundle: Bundle(for: EntryListViewModel.self),
        comment: "Error message shown when deleting an entry fails"
    )

    public init(
        loader: @escaping LoadEntries,
        delete: @escaping DeleteEntry = { _ in },
        currentDate: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.loader = loader
        self.deleteEntry = delete
        self.currentDate = currentDate
        self.timestampFormatter = RelativeDateTimeFormatter()
        self.timestampFormatter.calendar = calendar
        self.timestampFormatter.locale = locale
    }

    public func loadEntries() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedEntries = try await loader()
            guard !Task.isCancelled else { return }

            let now = currentDate()
            entries = loadedEntries.filter { !deletedEntryIDs.contains($0.id) }.map {
                EntryDTO(
                    id: $0.id,
                    text: $0.text,
                    imageURL: $0.imageURL,
                    audioURL: $0.audioURL,
                    timestamp: timestampFormatter.localizedString(for: $0.createdAt, relativeTo: now)
                )
            }
        } catch {
            guard !Task.isCancelled else { return }

            errorMessage = Self.loadErrorMessage
        }
    }

    public func delete(_ id: UUID) async {
        do {
            errorMessage = nil
            try await deleteEntry(id)
            guard !Task.isCancelled else { return }

            deletedEntryIDs.insert(id)
            guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
            entries.remove(at: index)
        } catch {
            guard !Task.isCancelled else { return }

            errorMessage = Self.deleteErrorMessage
        }
    }
}
