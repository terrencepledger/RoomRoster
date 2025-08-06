import Foundation

/// Parses comma‑separated lists and ranges of `PropertyTag` values.
///
/// Use this when bulk‑creating items. A string like `"A0001-A0005,B0001"`
/// expands to `[A0001, A0002, A0003, A0004, A0005, B0001]`. These tags can
/// then be validated and used to instantiate individual `Item` records
/// that share an `ItemGroup`. By centralizing the parsing logic here, the
/// UI can accept flexible input while keeping property tags unique and
/// correctly counted against the desired quantity.

struct PropertyTagRange: Hashable, Sequence, Codable {
    var tags: [PropertyTag]

    init(tags: [PropertyTag]) {
        self.tags = tags
    }

    init?(from string: String) {
        var result: [PropertyTag] = []
        for segment in string.split(separator: ",") {
            let part = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            if part.contains("-") {
                let ends = part.split(separator: "-", maxSplits: 1)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                guard ends.count == 2,
                      let start = PropertyTag(rawValue: ends[0]),
                      let end = PropertyTag(rawValue: ends[1]) else { return nil }
                let prefix = String(start.rawValue.prefix(1))
                guard prefix == String(end.rawValue.prefix(1)),
                      let startNum = Int(start.rawValue.dropFirst()),
                      let endNum = Int(end.rawValue.dropFirst()),
                      startNum <= endNum else { return nil }
                for num in startNum...endNum {
                    let tagString = String(format: "%@%04d", prefix, num)
                    guard let tag = PropertyTag(rawValue: tagString) else { return nil }
                    result.append(tag)
                }
            } else if let tag = PropertyTag(rawValue: part) {
                result.append(tag)
            } else {
                return nil
            }
        }
        self.tags = result
    }

    func makeIterator() -> IndexingIterator<[PropertyTag]> {
        tags.makeIterator()
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let range = PropertyTagRange(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid property tag range")
        }
        self = range
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Self.collapsedString(from: tags))
    }

    func stringValue() -> String {
        Self.collapsedString(from: tags)
    }

    static func collapsedString(from tags: [PropertyTag]) -> String {
        let sorted = tags.sorted { $0.rawValue < $1.rawValue }
        var result: [String] = []
        var index = 0
        while index < sorted.count {
            let startTag = sorted[index]
            let prefix = String(startTag.rawValue.prefix(1))
            let startNum = Int(startTag.rawValue.dropFirst())!
            var endIndex = index
            var lastNum = startNum

            while endIndex + 1 < sorted.count {
                let nextTag = sorted[endIndex + 1]
                let nextPrefix = String(nextTag.rawValue.prefix(1))
                let nextNum = Int(nextTag.rawValue.dropFirst())!
                if nextPrefix == prefix && nextNum == lastNum + 1 {
                    lastNum = nextNum
                    endIndex += 1
                } else {
                    break
                }
            }

            if endIndex > index {
                result.append(String(format: "%@%04d-%@%04d", prefix, startNum, prefix, lastNum))
            } else {
                result.append(startTag.rawValue)
            }

            index = endIndex + 1
        }

        return result.joined(separator: ",")
    }
}
