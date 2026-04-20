import Foundation
import SwiftData

@Model
final class EntryDataModel {
    var id: UUID
    var text: String?
    var imageURL: URL?
    var audioURL: URL?
    var createdAt: Date

    init(entry: Entry) {
        self.id = entry.id
        self.text = entry.text
        self.imageURL = entry.imageURL
        self.audioURL = entry.audioURL
        self.createdAt = entry.createdAt
    }

    var domainEntry: Entry {
        get throws {
            Entry(
                id: id,
                text: text,
                imageURL: imageURL,
                audioURL: audioURL,
                createdAt: createdAt,
            )
        }
    }
}
