import Foundation

if CommandLine.arguments.count != 2 {
    print("Usage: pilotconvert <mac pilot file>")
    exit(1)
}

do {
    try convertMacToWin(url: URL(fileURLWithPath: CommandLine.arguments[1]))
} catch let err {
    if let err = err as? LocalizedError {
        print("Error: \(err.localizedDescription)")
    } else {
        print("Error: \(err)")
    }
    exit(1)
}

func convertMacToWin(url: URL) throws {
    // Determine which fork to read
    var input = url
    let values = try url.resourceValues(forKeys: [.fileSizeKey, .totalFileSizeKey])
    if (values.totalFileSize! - values.fileSize!) > 0 {
        input = url.appendingPathComponent("..namedfork/rsrc")
    }

    // Read the file and find the NpïL resources
    let resourceMap = try ResourceFile.read(try Data(contentsOf: input))
    guard let npils = resourceMap[FourCharCode(fourCharString: "NpïL")],
          let npil1 = npils.first(where: { $0.id == 128 }),
          let npil2 = npils.first(where: { $0.id == 129 })
    else {
        throw ConversionError.missingResources
    }
    
    // First resource
    let mac1 = BinaryDataReader(SimpleCrypt.convert(npil1.data))
    let win = BinaryDataWriter(bigEndian: false)
    var converter = BinaryDataConverter(reader: mac1, writer: win)
    
    // Write the length and convert the data
    win.write(59730 as UInt32)
    try converter.short(5133)
    try converter.long(1)
    for _ in 0..<16 {
        try converter.byte(4)
        try converter.short(8)
    }
    for _ in 0..<16 {
        try converter.short(17)
        try mac1.advance(2)
        try converter.long(1)
        try converter.short(6)
        try converter.byte(3)
        try mac1.advance(1)
        try converter.short(18)
        try converter.long(2)
        try converter.short(6)
        try converter.byte(2169)
        try mac1.advance(3)
    }
    try converter.byte(12048)
    try converter.short(320)
    try converter.long(1)
    
    // Second resource
    let mac2 = BinaryDataReader(SimpleCrypt.convert(npil2.data))
    converter.reader = mac2
    
    // Write the length and convert the data
    win.write(26366 as UInt32)
    try converter.short(6211)
    try converter.byte(2)
    try converter.short(5768)
    try converter.byte(64)
    try converter.short(131)
    try converter.byte(32)
    try converter.short(1024)
    
    // Write the ship name
    try win.writeCString(npil2.name)
    
    // Write the output file
    let output = url.appendingPathExtension("plt")
    try win.data.write(to: output)
    
    // Remove the input file
    try? FileManager.default.removeItem(at: url)
}

struct BinaryDataConverter {
    var reader: BinaryDataReader
    var writer: BinaryDataWriter
    
    func byte(_ count: Int) throws {
        writer.writeData(try reader.readData(length: count))
    }
    func short(_ count: Int) throws {
        for _ in 0..<count {
            writer.write(try reader.read() as UInt16)
        }
    }
    func long(_ count: Int) throws {
        for _ in 0..<count {
            writer.write(try reader.read() as UInt32)
        }
    }
}

enum ConversionError: LocalizedError {
    case missingResources
    var errorDescription: String? {
        switch self {
        case .missingResources:
            return NSLocalizedString("NpïL resources not found.", comment: "")
        }
    }
}
