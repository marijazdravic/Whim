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

    public var text = ""
    public private(set) var isSaving = false

    public init(createEntry: @escaping CreateEntry) {
        self.createEntry = createEntry
    }

    public func saveText() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await createEntry(CreateEntryInput(text: text, imageURL: nil, audioURL: nil))
        } catch {}
    }
}
