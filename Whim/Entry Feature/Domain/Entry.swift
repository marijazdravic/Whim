//
//  Entry.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public struct Entry: Equatable {
    public let id: UUID
    public let text: String?
    public let createdAt: Date
    
    public init(id: UUID, text: String?, createdAt: Date) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}
 
