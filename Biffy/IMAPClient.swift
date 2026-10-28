import Foundation
import Network

struct IMAPResponse {
    let text: String
    let literals: [Data]
}

enum IMAPError: LocalizedError {
    case connectionFailed(String)
    case connectionClosed
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case let .connectionFailed(msg):
            "IMAP connection failed: \(msg)"
        case .connectionClosed:
            "IMAP connection closed"
        case let .commandFailed(msg):
            "IMAP error: \(msg)"
        }
    }
}

/// Minimal IMAP client that supports only the commands Biffy needs.
actor IMAPClient {
    private let connection: NWConnection
    private var buffer = Data()
    private var tagCounter = 0

    init(host: String, port: UInt16) {
        connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: .tls
        )
    }

    func connect() async throws {
        let once = ResumeOnce()

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    once.run { cont.resume() }
                case let .failed(err), let .waiting(err):
                    once.run { cont.resume(throwing: IMAPError.connectionFailed(err.localizedDescription)) }
                case .cancelled:
                    once.run { cont.resume(throwing: IMAPError.connectionClosed) }
                default:
                    break
                }
            }

            connection.start(queue: .global())
        }

        let greeting = try await readResponse()

        if !greeting.text.hasPrefix("* OK") {
            throw IMAPError.connectionFailed(greeting.text)
        }
    }

    func close() {
        connection.cancel()
    }

    func command(_ cmd: String) async throws -> [IMAPResponse] {
        tagCounter += 1
        let tag = "A\(tagCounter)"
        try await send("\(tag) \(cmd)\r\n")
        var untagged: [IMAPResponse] = []

        while true {
            let resp = try await readResponse()

            if resp.text.hasPrefix("\(tag) ") {
                let status = resp.text.dropFirst(tag.count + 1)

                if status.hasPrefix("OK") {
                    return untagged
                }

                throw IMAPError.commandFailed(String(status))
            }

            untagged.append(resp)
        }
    }

    static func quote(_ str: String) -> String {
        let escaped = str.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private func send(_ str: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            connection.send(content: Data(str.utf8), completion: .contentProcessed { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            })
        }
    }

    /// Reads one response. Literals ({n}) are collected separately and the text continues after them.
    private func readResponse() async throws -> IMAPResponse {
        var text = ""
        var literals: [Data] = []

        while true {
            let line = try await readLine()
            text += line

            guard let match = line.firstMatch(of: /\{(\d+)\}$/), let size = Int(match.1) else {
                return IMAPResponse(text: text, literals: literals)
            }

            try await literals.append(readBytes(size))
        }
    }

    private func readLine() async throws -> String {
        let crlf = Data("\r\n".utf8)

        while true {
            if let range = buffer.range(of: crlf) {
                let line = buffer[..<range.lowerBound]
                buffer = Data(buffer[range.upperBound...])
                return Data(line).lossyUTF8
            }

            try await fill()
        }
    }

    private func readBytes(_ size: Int) async throws -> Data {
        while buffer.count < size {
            try await fill()
        }

        let data = Data(buffer.prefix(size))
        buffer = Data(buffer.dropFirst(size))
        return data
    }

    private func fill() async throws {
        let data: Data = try await withCheckedThrowingContinuation { cont in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                if let error {
                    cont.resume(throwing: error)
                } else if let data, !data.isEmpty {
                    cont.resume(returning: data)
                } else if isComplete {
                    cont.resume(throwing: IMAPError.connectionClosed)
                } else {
                    cont.resume(returning: Data())
                }
            }
        }

        buffer.append(data)
    }
}

/// NWConnection keeps reporting state changes after "ready", so resume the continuation only once.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false

    func run(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        if !done {
            done = true
            body()
        }
    }
}
