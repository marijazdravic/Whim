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

    public init(loader: @escaping LoadEntries) {
        self.loader = loader
    }
}
