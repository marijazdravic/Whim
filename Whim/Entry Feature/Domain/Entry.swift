//
//  Entry.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public struct Entry: Equatable, Sendable {
    public enum ValidationError: Swift.Error, Equatable {
        case missingContent
    }

    public let id: UUID
    public let text: String?
    public let imageURL: URL?
    public let audioURL: URL?
    public let createdAt: Date

    public init(
        id: UUID,
        text: String?,
        imageURL: URL?,
        audioURL: URL?,
        createdAt: Date
    ) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.audioURL = audioURL
        self.createdAt = createdAt
    }

    public func validate() throws {
        guard hasContent else {
            throw ValidationError.missingContent
        }
    }

    private var hasContent: Bool {
        text?.hasContent == true || imageURL != nil || audioURL != nil
    }
}

extension String {
    var hasContent: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
