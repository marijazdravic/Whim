//
//  EntryDTO.swift
//  Whim
//
//  Created by Marija Zdravic on 28.04.2026..
//

import Foundation

public struct EntryDTO: Equatable, Identifiable {
    public let id: UUID
    public let text: String?
    public let imageURL: URL?
    public let audioURL: URL?
    public let timestamp: String

    public init(id: UUID, text: String?, imageURL: URL?, audioURL: URL?, timestamp: String) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.audioURL = audioURL
        self.timestamp = timestamp
    }
}
