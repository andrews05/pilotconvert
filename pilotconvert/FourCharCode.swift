import Foundation

// Allow easy translation between String and UInt32/FourCharCode, in the same manner as classic OSTypes
public extension FourCharCode {
    /// Returns a four character String representation of this integer, using macOSRoman encoding.
    var fourCharString: String {
        guard self != 0 else {
            return ""
        }
        let bytes = [
            UInt8(self >> 24),
            UInt8(self >> 16 & 0xFF),
            UInt8(self >> 8 & 0xFF),
            UInt8(self & 0xFF)
        ]
        return String(bytes: bytes, encoding: .macOSRoman) ?? ""
    }

    /// Creates a new instance from four characters of a String, using macOSRoman encoding.
    init(fourCharString: String) {
        self = 0
        guard fourCharString != "" else {
            return
        }
        var bytes: [UInt8] = [0, 0, 0, 0]
        let max = Swift.min(fourCharString.count, 4)
        var used = 0
        var range = fourCharString.startIndex..<fourCharString.endIndex
        _ = fourCharString.getBytes(&bytes, maxLength: max, usedLength: &used, encoding: .macOSRoman, range: range, remaining: &range)
        if used == max {
            self = bytes.reduce(0) { $0 << 8 | Self($1) }
        }
    }
}
