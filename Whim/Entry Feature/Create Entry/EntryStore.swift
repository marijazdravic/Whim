//
//  EntryStore.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public protocol EntryStore {
    func insert(_ entry: Entry) throws
}
