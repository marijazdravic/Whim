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
    
    public private(set) var entries = [EntryDTO]()
    public private(set) var errorMessage: String?
    public private(set) var isLoading = false
    public static let loadErrorMessage = NSLocalizedString(
        "ENTRY_LIST_LOAD_ERROR",
        tableName: "EntryList",
        bundle: Bundle(for: EntryListViewModel.self),
        comment: "Error message shown when loading entries fails"
    )

    public init(loader: @escaping LoadEntries) {
        self.loader = loader
    }

    public func loadEntries() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedEntries = try await loader()
            entries = loadedEntries.map {
                EntryDTO(
                    id: $0.id,
                    text: $0.text,
                    imageURL: $0.imageURL,
                    audioURL: $0.audioURL
                )
            }
        } catch {
            errorMessage = Self.loadErrorMessage
        }
    }
}
