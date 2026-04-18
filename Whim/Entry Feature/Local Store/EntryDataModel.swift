import Foundation
import SwiftData

@Model
public final class EntryDataModel {
    public var id: UUID
    public var text: String?
    public var imageURL: URL?
    public var audioURL: URL?
    public var createdAt: Date
    public var status: String

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

public enum EntryStatusMappingError: Error, Equatable {
    case invalidStatus(String)
}

public extension EntryStatus {
    init(localValue: String) throws {
        switch localValue {
        case "draft": self = .draft
        default: throw EntryStatusMappingError.invalidStatus(localValue)
        }
    }
}
