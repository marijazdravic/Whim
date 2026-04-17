import Foundation
import Testing
import SwiftData
import Whim

@Model
final class EntryDataModel {
    var id: UUID
    var text: String?
    var imageURL: URL?
    var audioURL: URL?
    var createdAt: Date
    var status: String
    
    init(entry: Entry) {
        self.id = entry.id
        self.text = entry.text
        self.imageURL = entry.imageURL
        self.audioURL = entry.audioURL
        self.createdAt = entry.createdAt
        self.status = Self.mapStatus(entry.status)
    }
    
    private static func mapStatus(_ status: EntryStatus) -> String {
        switch status {
        case .draft:
            return "draft"
        @unknown default:
            assertionFailure("Unhandled EntryStatus: \(status)")
            return "unhandled-entry-status"
        }
    }
}

enum EntryStatusMappingError: Error {
    case invalidStatus(String)
}

extension EntryStatus {
    init(localValue: String) throws {
        switch localValue {
        case "draft": self = .draft
        default: throw EntryStatusMappingError.invalidStatus(localValue)
        }
    }
}

final class SwiftDataEntryStore: EntryStore {
    private let container: ModelContainer
    
    init(container: ModelContainer) {
        self.container = container
    }
    
    func insert(_ entry: Entry) throws {
        let context = ModelContext(container)
        context.insert(EntryDataModel(entry: entry))
        try context.save()
    }
}


struct SwiftDataEntryStoreTests {
    @Test
    func insert_persistsOneEntry() throws {
        let (sut, container) = try makeSUT()
        
        try sut.insert(anyEntry())
        
        let saved = try fetchEntries(from: container)
        #expect(saved.count == 1)
    }
    
    // MARK: - Helpers
    
    private func makeSUT() throws -> (SwiftDataEntryStore, ModelContainer) {
        let container = try ModelContainer(
            for: EntryDataModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return (SwiftDataEntryStore(container: container), container)
    }
    
    private func fetchEntries(from container: ModelContainer) throws -> [EntryDataModel] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<EntryDataModel>())
    }
    
    private func anyEntry() -> Entry {
        Entry(
            id: UUID(),
            text: "Any text",
            imageURL: nil,
            audioURL: nil,
            createdAt: Date(),
            status: .draft
        )
    }
}
