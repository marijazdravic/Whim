//
//  CreateEntryInput.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public struct CreateEntryInput: Equatable, Sendable {
    public let text: String?
    public let imageURL: URL?
    public let audioURL: URL?

    public init(text: String?, imageURL: URL?, audioURL: URL?) {
        self.text = text
        self.imageURL = imageURL
        self.audioURL = audioURL
    }
}
