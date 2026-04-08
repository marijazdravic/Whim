//
//  CreateEntryInput.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public struct CreateEntryInput: Equatable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}
