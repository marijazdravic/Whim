import Foundation
import Testing
import Whim

struct EntryTests {
    @Test
    func validate_throwsMissingContentWhenAllContentFieldsAreNil() {
        let entry = anyEntry(text: nil, imageURL: nil, audioURL: nil)

        #expect(throws: Entry.ValidationError.missingContent) {
            try entry.validate()
        }
    }

    @Test(arguments: [
        "",
        " ",
        "   ",
        "\t",
        "\n",
        " \t\n ",
        "\r\n",
    ])
    func validate_throwsMissingContentWhenTextIsWhitespaceOnlyAndNoOtherContent(
        _ text: String
    ) {
        let entry = anyEntry(text: text, imageURL: nil, audioURL: nil)

        #expect(throws: Entry.ValidationError.missingContent) {
            try entry.validate()
        }
    }

    @Test
    func validate_doesNotThrowWhenTextHasContent() throws {
        let entry = anyEntry(text: anyText(), imageURL: nil, audioURL: nil)

        try entry.validate()
    }

    @Test
    func validate_doesNotThrowWhenImageURLIsPresent() throws {
        let entry = anyEntry(text: nil, imageURL: anyImageURL(), audioURL: nil)

        try entry.validate()
    }

    @Test
    func validate_doesNotThrowWhenAudioURLIsPresent() throws {
        let entry = anyEntry(text: nil, imageURL: nil, audioURL: anyAudioURL())

        try entry.validate()
    }

    @Test
    func validate_doesNotThrowWhenWhitespaceTextIsAccompaniedByMedia() throws {
        let entry = anyEntry(
            text: whitespaceOnlyText(),
            imageURL: anyImageURL(),
            audioURL: nil
        )

        try entry.validate()
    }
}
