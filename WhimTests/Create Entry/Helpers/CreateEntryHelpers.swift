//
//  CreateEntryHelpers.swift
//  WhimTests
//
//  Created by Marija Zdravic on 18.04.2026..
//

import Foundation

func anyText() -> String {
    "Any text"
}

func anyAudioURL() -> URL {
    URL(string: "file:///some/audio.m4a")!
}

func anyImageURL() -> URL {
    URL(string: "file:///some/image.jpg")!
}

func anyEntryID() ->  UUID {
    UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
}

func anyEntryDate() -> Date {
    Date(timeIntervalSince1970: 1_598_627_222)
}


