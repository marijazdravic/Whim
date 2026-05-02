//
//  CaptureViewModel.swift
//  Whim
//
//  Created by Marija Zdravic on 02.05.2026..
//

import Foundation
import Observation

public typealias CreateEntry = (CreateEntryInput) async throws -> Void

@MainActor
@Observable
public final class CaptureViewModel {
    private let createEntry: CreateEntry

    public var text = ""
    public private(set) var isSaving = false
    public private(set) var errorMessage: String?
    public static let saveErrorMessage = NSLocalizedString(
        "CAPTURE_SAVE_ERROR",
        tableName: "Capture",
        bundle: Bundle(for: CaptureViewModel.self),
        comment: "Error message shown when saving an entry fails"
    )

    public init(createEntry: @escaping CreateEntry) {
        self.createEntry = createEntry
    }

    public func saveText() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await createEntry(CreateEntryInput(text: text, imageURL: nil, audioURL: nil))
            text = ""
        } catch {
            errorMessage = Self.saveErrorMessage
        }
    }
}
