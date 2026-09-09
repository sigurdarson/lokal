import Foundation

/// Minimal HTTP/1.1 client pieces for talking to the Docker Engine over a Unix socket.
/// Pure functions, so response parsing is unit tested without a daemon.
enum DockerHTTP {
    enum Failure: Error, Equatable {
        case malformedResponse
        case unexpectedStatus(Int)
    }

    static func request(path: String) -> Data {
        Data("GET \(path) HTTP/1.1\r\nHost: docker\r\nAccept: application/json\r\nConnection: close\r\n\r\n".utf8)
    }

    /// Splits status line, headers and body; de-chunks when needed.
    static func parseResponse(_ data: Data) throws -> (status: Int, body: Data) {
        guard let separator = data.range(of: Data("\r\n\r\n".utf8)) else { throw Failure.malformedResponse }
        let head = String(decoding: data[..<separator.lowerBound], as: UTF8.self)
        var lines = head.components(separatedBy: "\r\n")
        guard let statusLine = lines.first else { throw Failure.malformedResponse }
        lines.removeFirst()
        let statusParts = statusLine.split(separator: " ")
        guard statusParts.count >= 2, let status = Int(statusParts[1]) else { throw Failure.malformedResponse }

        var chunked = false
        var contentLength: Int?
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if name == "transfer-encoding", value.lowercased().contains("chunked") { chunked = true }
            if name == "content-length" { contentLength = Int(value) }
        }

        let rawBody = data[separator.upperBound...]
        if chunked {
            return (status, try dechunk(rawBody))
        }
        if let contentLength, contentLength <= rawBody.count {
            return (status, Data(rawBody.prefix(contentLength)))
        }
        return (status, Data(rawBody))
    }

    /// True once `data` holds a whole response, judged by Content-Length or the chunked terminator.
    /// Without either header, only EOF can tell, so this returns false.
    static func isComplete(_ data: Data) -> Bool {
        guard let separator = data.range(of: Data("\r\n\r\n".utf8)) else { return false }
        let head = String(decoding: data[..<separator.lowerBound], as: UTF8.self).lowercased()
        let body = data[separator.upperBound...]
        for line in head.components(separatedBy: "\r\n") {
            if line.hasPrefix("content-length:"),
                let length = Int(line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces))
            {
                return body.count >= length
            }
            if line.hasPrefix("transfer-encoding:"), line.contains("chunked") {
                return body.count >= 5 && body.suffix(5).elementsEqual(Data("0\r\n\r\n".utf8))
            }
        }
        return false
    }

    static func dechunk(_ data: Data) throws -> Data {
        var result = Data()
        var index = data.startIndex
        let crlf = Data("\r\n".utf8)
        while index < data.endIndex {
            guard let lineEnd = data[index...].range(of: crlf) else { throw Failure.malformedResponse }
            let sizeText =
                String(decoding: data[index..<lineEnd.lowerBound], as: UTF8.self)
                .split(separator: ";").first.map(String.init) ?? ""
            guard let size = Int(sizeText.trimmingCharacters(in: .whitespaces), radix: 16) else {
                throw Failure.malformedResponse
            }
            if size == 0 { break }
            let start = lineEnd.upperBound
            let end = data.index(start, offsetBy: size, limitedBy: data.endIndex) ?? data.endIndex
            result.append(data[start..<end])
            index = data.index(end, offsetBy: 2, limitedBy: data.endIndex) ?? data.endIndex
        }
        return result
    }

    /// Maps the `/containers/json` payload to `ContainerInfo`, keeping only containers with published host ports.
    static func containers(from body: Data) throws -> [ContainerInfo] {
        guard let array = try JSONSerialization.jsonObject(with: body) as? [[String: Any]] else {
            throw Failure.malformedResponse
        }
        return array.compactMap { object in
            guard let id = object["Id"] as? String else { return nil }
            let names = (object["Names"] as? [String]) ?? []
            let name = names.first.map { $0.hasPrefix("/") ? String($0.dropFirst()) : $0 } ?? String(id.prefix(12))
            let image = (object["Image"] as? String) ?? ""
            let ports = ((object["Ports"] as? [[String: Any]]) ?? [])
                .compactMap { port -> UInt16? in
                    guard let type = port["Type"] as? String, type == "tcp" else { return nil }
                    guard let published = port["PublicPort"] as? Int, published > 0, published <= 65535 else {
                        return nil
                    }
                    return UInt16(published)
                }
            let unique = Array(Set(ports)).sorted()
            return ContainerInfo(id: id, name: name, image: image, publishedPorts: unique)
        }
    }
}
