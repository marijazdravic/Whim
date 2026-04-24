import Foundation

public final class EntryLoader {
    private let store: EntryStore

    public init(store: EntryStore) {
        self.store = store
    }

    public func load() throws -> [Entry] {
        try store
            .retrieveAll()
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }
}
