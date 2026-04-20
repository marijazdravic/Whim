//
//  Entry.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public struct Entry: Equatable, Sendable {
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
}
