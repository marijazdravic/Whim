import Foundation
import SwiftData

public final class SwiftDataEntryStore: EntryStore {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func insert(_ entry: Entry) throws {
        let context = ModelContext(container)
        context.insert(EntryDataModel(entry: entry))
        try context.save()
    }

    public func retrieve(by id: UUID) throws -> Entry? {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<EntryDataModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try context.fetch(descriptor).first else { return nil }
        return Entry(
            id: model.id,
            text: model.text,
            imageURL: model.imageURL,
            audioURL: model.audioURL,
            createdAt: model.createdAt,
            status: try EntryStatus(localValue: model.status)
        )
    }
}
