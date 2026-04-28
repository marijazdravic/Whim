//
//  EntryListViewModel.swift
//  Whim
//
//  Created by Marija Zdravic on 28.04.2026..
//

import Foundation
import Observation

public typealias LoadEntries = () async throws -> [Entry]

@MainActor
@Observable
public final class EntryListViewModel {
    private let loader: LoadEntries
    private let currentDate: () -> Date
    private let calendar: Calendar
    private let locale: Locale
    
    public private(set) var entries = [EntryDTO]()
    public private(set) var errorMessage: String?
    public private(set) var isLoading = false
    public static let loadErrorMessage = NSLocalizedString(
        "ENTRY_LIST_LOAD_ERROR",
        tableName: "EntryList",
        bundle: Bundle(for: EntryListViewModel.self),
        comment: "Error message shown when loading entries fails"
    )

    public init(
        loader: @escaping LoadEntries,
        currentDate: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.loader = loader
        self.currentDate = currentDate
        self.calendar = calendar
        self.locale = locale
    }

    public func loadEntries() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedEntries = try await loader()
            let now = currentDate()
            entries = loadedEntries.map {
                EntryDTO(
                    id: $0.id,
                    text: $0.text,
                    imageURL: $0.imageURL,
                    audioURL: $0.audioURL,
                    timestamp: timestamp(for: $0, relativeTo: now)
                )
            }
        } catch {
            errorMessage = Self.loadErrorMessage
        }
    }

    private func timestamp(for entry: Entry, relativeTo currentDate: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        return formatter.localizedString(for: entry.createdAt, relativeTo: currentDate)
    }
}
