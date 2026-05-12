//
//  CaptureViewModel.swift
//  Whim
//
//  Created by Marija Zdravic on 02.05.2026..
//

import Foundation
import Observation

public typealias CreateEntry = (CreateEntryInput) async throws -> Void
public typealias Sleep = @MainActor (Duration) async throws -> Void

@MainActor
@Observable
public final class CaptureViewModel {
    private let createEntry: CreateEntry
    private let sleep: Sleep
    private var requestID = 0
    private var scheduledSaveTask: Task<Void, Never>?

    public var text = ""
    public var hasDraft: Bool {
        text.hasContent
    }
    public var canSaveText: Bool {
        hasDraft
    }
    public private(set) var isSaving = false
    public private(set) var errorMessage: String?
    public static let saveErrorMessage = NSLocalizedString(
        "CAPTURE_SAVE_ERROR",
        tableName: "Capture",
        bundle: Bundle(for: CaptureViewModel.self),
        comment: "Error message shown when saving an entry fails"
    )

    public init(
        createEntry: @escaping CreateEntry,
        sleep: @escaping Sleep = { try await Task.sleep(for: $0) }
    ) {
        self.createEntry = createEntry
        self.sleep = sleep
    }

    public func updateText(_ newText: String) {
        text = newText
        requestID += 1
        scheduleSaveText()
    }

    public func saveText() async {
        guard canSaveText, !isSaving else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let draft = text
        let savedRequestID = requestID

        do {
            try await createEntry(CreateEntryInput(text: draft, imageURL: nil, audioURL: nil))
            if requestID == savedRequestID {
                text = ""
            }
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            guard requestID == savedRequestID else { return }

            errorMessage = Self.saveErrorMessage
        }
    }

    public func scheduleSaveText() {
        scheduledSaveTask?.cancel()
        let savedRequestID = requestID

        scheduledSaveTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await sleep(CaptureAutosavePolicy.delay)
                guard !Task.isCancelled else { return }
                guard requestID == savedRequestID else { return }

                await saveText()
            } catch {
            }
        }
    }

    public func discardDraft() {
        scheduledSaveTask?.cancel()
        text = ""
        requestID += 1
        errorMessage = nil
    }
}

private extension String {
    var hasContent: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
