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

enum EntryStatusMappingError: Error, Equatable {
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
    func insert_persistsEntry() throws {
        let (sut, container) = try makeSUT()
        let entry = Entry(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            text: "Any text",
            imageURL: URL(string: "file:///some/image.jpg"),
            audioURL: URL(string: "file:///some/audio.m4a"),
            createdAt: Date(timeIntervalSince1970: 123),
            status: .draft
        )
        
        try sut.insert(entry)

        let saved = try fetchEntries(from: container)
        #expect(saved.count == 1)
        let model = try #require(saved.first)
        #expect(model.id == entry.id)
        #expect(model.text == entry.text)
        #expect(model.imageURL == entry.imageURL)
        #expect(model.audioURL == entry.audioURL)
        #expect(model.createdAt == entry.createdAt)
        #expect(model.status == "draft")
    }
    
    @Test
    func entryStatus_initLocalValue_deliversDraftOnDraftValue() throws {
        let status = try EntryStatus(localValue: "draft")

        #expect(status == .draft)
    }

    @Test
    func entryStatus_initLocalValue_throwsOnInvalidValue() {
        #expect(throws: EntryStatusMappingError.invalidStatus("invalid")) {
            try EntryStatus(localValue: "invalid")
        }
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
}
