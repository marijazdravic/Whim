//
//  CaptureViewModel.swift
//  Whim
//
//  Created by Marija Zdravic on 02.05.2026..
//

import Observation

public typealias CreateEntry = (CreateEntryInput) async throws -> Void

@MainActor
@Observable
public final class CaptureViewModel {
    private let createEntry: CreateEntry

    public init(createEntry: @escaping CreateEntry) {
        self.createEntry = createEntry
    }
}
