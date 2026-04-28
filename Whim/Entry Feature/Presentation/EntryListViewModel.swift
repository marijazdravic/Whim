//
//  EntryListViewModel.swift
//  Whim
//
//  Created by Marija Zdravic on 28.04.2026..
//

import Observation

public typealias LoadEntries = () async throws -> [Entry]

@MainActor
@Observable
public final class EntryListViewModel {
    private let loader: LoadEntries
    
    public private(set) var entries = [EntryDTO]()
    public private(set) var isLoading = false

    public init(loader: @escaping LoadEntries) {
        self.loader = loader
    }

    public func loadEntries() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        if let loadedEntries = try? await loader() {
            entries = loadedEntries.map {
                EntryDTO(
                    id: $0.id,
                    text: $0.text,
                    imageURL: $0.imageURL,
                    audioURL: $0.audioURL
                )
            }
        }
    }
}
