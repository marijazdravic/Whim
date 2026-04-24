import Foundation

public final class EntryLoader {
    private let store: EntryStore

    public init(store: EntryStore) {
        self.store = store
    }

    public func load() throws -> [Entry] {
        try store.retrieveAll()
    }
}
