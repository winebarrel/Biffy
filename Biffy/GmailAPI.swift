import Foundation

struct Mail: Identifiable {
    let uid: UInt32
    let threadID: String
    let from: String
    let subject: String
    let date: Date

    var id: UInt32 {
        uid
    }

    func url(_ email: String) -> String {
        "https://mail.google.com/mail/?authuser=\(email)#inbox/\(threadID)"
    }
}

typealias Mails = [Mail]

func - (left: Mails, right: Mails) -> Mails {
    let rightIDs = Set(right.map { $0.id })
    return left.filter { !rightIDs.contains($0.id) }
}

struct GmailAPI {
    let email: String
    let appPassword: String

    private static let host = "imap.gmail.com"
    private static let port: UInt16 = 993
    private static let timeout: Duration = .seconds(30)

    /// Returns the number of unread mails in INBOX and the newest ones up to `limit`.
    func fetchUnread(limit: Int = Constants.maxMails) async throws -> (count: Int, mails: Mails) {
        try await withClient { client in
            try await login(client)
            _ = try await client.command("EXAMINE INBOX")

            let uids = try await client.command("UID SEARCH UNSEEN")
                .filter { $0.text.hasPrefix("* SEARCH") }
                .flatMap { $0.text.split(separator: " ").dropFirst(2).compactMap { UInt32($0) } }
                .sorted(by: >)

            if uids.isEmpty {
                return (0, [])
            }

            let target = uids.prefix(limit).map { String($0) }.joined(separator: ",")
            let mails = try await client.command(
                "UID FETCH \(target) (UID X-GM-THRID INTERNALDATE BODY.PEEK[HEADER.FIELDS (FROM SUBJECT)])"
            ).compactMap { Self.parseFetch($0) }

            _ = try? await client.command("LOGOUT")

            return (uids.count, mails.sorted { $0.date > $1.date })
        }
    }

    func markAsRead(_ uid: UInt32) async throws {
        try await withClient { client in
            try await login(client)
            _ = try await client.command("SELECT INBOX")
            _ = try await client.command("UID STORE \(uid) +FLAGS.SILENT (\\Seen)")
            _ = try? await client.command("LOGOUT")
        }
    }

    private func login(_ client: IMAPClient) async throws {
        _ = try await client.command("LOGIN \(IMAPClient.quote(email)) \(IMAPClient.quote(appPassword))")
    }

    private func withClient<T: Sendable>(_ body: (IMAPClient) async throws -> T) async throws -> T {
        let client = IMAPClient(host: Self.host, port: Self.port)

        // NOTE: NWConnection does not respond to task cancellation, so close the connection to stop a stalled request.
        let watchdog = Task {
            try? await Task.sleep(for: Self.timeout)

            if !Task.isCancelled {
                await client.close()
            }
        }

        defer { watchdog.cancel() }

        do {
            try await client.connect()
            let result = try await body(client)
            await client.close()
            return result
        } catch {
            await client.close()
            throw error
        }
    }

    private static func parseFetch(_ resp: IMAPResponse) -> Mail? {
        let text = resp.text

        guard text.contains(" FETCH ("),
              let uidMatch = text.firstMatch(of: /\bUID (\d+)/), let uid = UInt32(uidMatch.1),
              let thrMatch = text.firstMatch(of: /X-GM-THRID (\d+)/), let thrid = UInt64(thrMatch.1),
              let dateMatch = text.firstMatch(of: /INTERNALDATE "([^"]+)"/),
              let date = parseInternalDate(String(dateMatch.1)),
              let header = resp.literals.first
        else {
            return nil
        }

        let fields = MIMEHeader.parse(header)

        return Mail(
            uid: uid,
            threadID: String(thrid, radix: 16),
            from: MIMEHeader.displayName(fields["from"] ?? ""),
            subject: fields["subject"] ?? "",
            date: date
        )
    }

    private static func parseInternalDate(_ str: String) -> Date? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "d-MMM-yyyy HH:mm:ss Z"
        return fmt.date(from: str.trimmingCharacters(in: .whitespaces))
    }
}
