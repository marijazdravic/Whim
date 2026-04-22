import Foundation
import SwiftData

public enum SwiftDataEntryStoreError: Error {
    case duplicateID
}

public final class SwiftDataEntryStore: EntryStore {
    private let container: ModelContainer
    
    private init(container: ModelContainer) {
        self.container = container
    }
    
    public convenience init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        let container = try ModelContainer(
            for: EntryDataModel.self,
            configurations: configuration
        )
        self.init(container: container)
    }
    
    public func insert(_ entry: Entry) throws {
        let context = ModelContext(container)
        let descriptor = descriptor(for: entry.id)
        
        guard try context.fetch(descriptor).isEmpty else {
            throw SwiftDataEntryStoreError.duplicateID
        }
        context.insert(EntryDataModel(entry: entry))
        try context.save()
    }
    
    public func retrieve(by id: UUID) throws -> Entry? {
        let context = ModelContext(container)
        let descriptor = descriptor(for: id)
        
        guard let model = try context.fetch(descriptor).first else {
            return nil
        }
        return try model.domainEntry
    }
    
    public func update(_ entry: Entry) throws {
        let context = ModelContext(container)
        let descriptor = descriptor(for: entry.id)

        guard let model = try context.fetch(descriptor).first else {
            return
        }
        model.text = entry.text
        model.imageURL = entry.imageURL
        model.audioURL = entry.audioURL
        model.createdAt = entry.createdAt
        try context.save()
    }

    public func delete(by id: UUID) throws {
        let context = ModelContext(container)
        let descriptor = descriptor(for: id)

        guard let model = try context.fetch(descriptor).first else {
            return
        }
        context.delete(model)
        try context.save()
    }


    private func descriptor(for id: UUID) -> FetchDescriptor<EntryDataModel> {
        FetchDescriptor<EntryDataModel>(
            predicate: #Predicate { $0.id == id }
        )
    }
}
