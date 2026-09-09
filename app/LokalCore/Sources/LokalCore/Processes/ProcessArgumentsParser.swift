/// Parses the `KERN_PROCARGS2` buffer layout:
/// `int32 argc`, then the executable path (NUL-terminated), NUL padding, then `argc` NUL-terminated
/// arguments, then the environment. Pure, for unit testing.
enum ProcessArgumentsParser {
    struct Result: Equatable {
        var executablePath: String
        var arguments: [String]
    }

    static func parse(_ buffer: [UInt8]) -> Result? {
        guard buffer.count > 4 else { return nil }
        let argc = Int(UInt32(buffer[0]) | UInt32(buffer[1]) << 8 | UInt32(buffer[2]) << 16 | UInt32(buffer[3]) << 24)
        var index = 4

        guard let pathEnd = buffer[index...].firstIndex(of: 0) else { return nil }
        let executablePath = String(decoding: buffer[index..<pathEnd], as: UTF8.self)
        index = pathEnd
        while index < buffer.count, buffer[index] == 0 { index += 1 }

        var arguments: [String] = []
        while arguments.count < argc, index < buffer.count {
            let end = buffer[index...].firstIndex(of: 0) ?? buffer.count
            arguments.append(String(decoding: buffer[index..<end], as: UTF8.self))
            index = end + 1
        }
        return Result(executablePath: executablePath, arguments: arguments)
    }
}
