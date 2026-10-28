import Foundation

enum MIMEHeader {
    /// Parses raw header lines into a dictionary keyed by lowercased field name, decoding encoded-words.
    static func parse(_ data: Data) -> [String: String] {
        let raw = data.lossyUTF8
        let unfolded = raw.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: #"\n[ \t]+"#, with: " ", options: .regularExpression)
        var fields: [String: String] = [:]

        for line in unfolded.split(separator: "\n") {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            fields[name] = decode(value)
        }

        return fields
    }

    /// Returns the display name of an address like `"Name" <addr>`, or the address itself.
    static func displayName(_ from: String) -> String {
        guard let open = from.firstIndex(of: "<") else {
            return from
        }

        let name = from[..<open].trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        if name.isEmpty {
            return from[from.index(after: open)...].trimmingCharacters(in: CharacterSet(charactersIn: ">"))
        }

        return name
    }

    /// Decodes RFC 2047 encoded-words. Adjacent words with the same charset are joined as bytes
    /// because some mailers split a multibyte character across words.
    static func decode(_ str: String) -> String {
        let pattern = /=\?([^?]+)\?([BbQq])\?([^?]*)\?=/
        var result = ""
        var pending = Data()
        var pendingCharset = ""
        var rest = str[...]

        func flush() {
            if !pending.isEmpty {
                result += String(data: pending, encoding: encoding(pendingCharset)) ?? pending.lossyUTF8
                pending = Data()
            }
        }

        while let match = rest.firstMatch(of: pattern) {
            let gap = rest[..<match.range.lowerBound]

            if !(pending.isEmpty || gap.allSatisfy(\.isWhitespace)) || pendingCharset != match.1.lowercased() {
                flush()
            }

            if pending.isEmpty {
                result += gap
            }

            pendingCharset = match.1.lowercased()

            if let bytes = decodeWord(String(match.3), encoding: String(match.2)) {
                pending.append(bytes)
            } else {
                flush()
                result += rest[match.range]
            }

            rest = rest[match.range.upperBound...]
        }

        flush()
        result += rest

        return result
    }

    private static func decodeWord(_ text: String, encoding: String) -> Data? {
        if encoding.uppercased() == "B" {
            var base64 = text
            base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
            return Data(base64Encoded: base64)
        }

        var data = Data()
        var idx = text.startIndex

        while idx < text.endIndex {
            let char = text[idx]

            if char == "_" {
                data.append(0x20)
            } else if char == "=", let byte = hexByte(text, at: idx) {
                data.append(byte)
                idx = text.index(idx, offsetBy: 3)
                continue
            } else {
                data.append(contentsOf: Array(String(char).utf8))
            }

            idx = text.index(after: idx)
        }

        return data
    }

    /// Parses "=XX" at the given index.
    private static func hexByte(_ text: String, at idx: String.Index) -> UInt8? {
        guard let end = text.index(idx, offsetBy: 3, limitedBy: text.endIndex) else {
            return nil
        }

        return UInt8(text[text.index(after: idx) ..< end], radix: 16)
    }

    private static func encoding(_ charset: String) -> String.Encoding {
        // NOTE: RFC 2231 allows a language suffix like "utf-8*ja".
        let name = charset.split(separator: "*").first.map(String.init) ?? charset
        let cfEnc = CFStringConvertIANACharSetNameToEncoding(name as CFString)

        if cfEnc == kCFStringEncodingInvalidId {
            return .utf8
        }

        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEnc))
    }
}
