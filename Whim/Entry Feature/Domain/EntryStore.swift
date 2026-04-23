//
//  EntryStore.swift
//  Whim
//
//  Created by Marija Zdravic on 08.04.2026..
//

import Foundation

public enum EntryStoreError: Error, Equatable {
    case duplicateID
    case notFound
}

public protocol EntryStore {
    func insert(_ entry: Entry) throws
    func retrieve(by id: UUID) throws -> Entry?
    func update(_ entry: Entry) throws
    func delete(by id: UUID) throws
}
