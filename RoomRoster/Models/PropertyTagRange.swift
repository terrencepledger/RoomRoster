import Foundation

/// Parses comma‑separated lists and ranges of `PropertyTag` values.
///
/// Use this when bulk‑creating items. A string like `"A0001-A0005,B0001"`
/// expands to `[A0001, A0002, A0003, A0004, A0005, B0001]`. These tags can
/// then be validated and used to instantiate individual `Item` records
/// that share an `ItemGroup`. By centralizing the parsing logic here, the
/// UI can accept flexible input while keeping property tags unique and
/// correctly counted against the desired quantity.

struct PropertyTagRange: Hashable, Sequence {
    var tags: [PropertyTag]

    init(tags: [PropertyTag]) {
        self.tags = tags
    }

    init?(from string: String) {
        var result: [PropertyTag] = []
        for segment in string.split(separator: ",") {
            let part = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            if part.contains("-") {
                let ends = part.split(separator: "-", maxSplits: 1).map { String($0) }
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
}
