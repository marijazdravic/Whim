import Foundation
import SwiftData

@Model
final class EntryDataModel {
    @Attribute(.unique) var id: UUID
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

    var domainEntry: Entry {
        get throws {
            Entry(
                id: id,
                text: text,
                imageURL: imageURL,
                audioURL: audioURL,
                createdAt: createdAt,
                status: try EntryStatus(localValue: status)
            )
        }
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
