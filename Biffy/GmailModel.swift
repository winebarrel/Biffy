import Foundation

@MainActor
class GmailModel: ObservableObject {
    enum Status: String {
        case noUnread = "envelope"
        case unread = "envelope.fill"
        case error = "exclamationmark.triangle"
    }

    @Published var mails: Mails = []
    @Published var unreadCount = 0
    @Published var status: Status = .noUnread
    @Published var updatedAt: Date?
    @Published var error: IMAPError?
    // NOTE: Do not notify unread mails that already exist at launch.
    private var fetched = false

    func update(_ api: GmailAPI) async {
        if api.email.isEmpty || api.appPassword.isEmpty {
            return
        }

        do {
            let (count, currMails) = try await api.fetchUnread()
            let newMails = currMails - mails

            mails = currMails
            unreadCount = count
            status = count > 0 ? .unread : .noUnread
            updatedAt = Date()
            error = nil

            if fetched, !newMails.isEmpty {
                notify(newMails, email: api.email)
            }

            fetched = true
        } catch let IMAPError.commandFailed(msg) {
            status = .error
            error = .commandFailed(msg)
            updatedAt = nil
        } catch {
            Logger.shared.error("failed to get unread mails: \(error)")
        }
    }

    func markAsRead(_ api: GmailAPI, uid: UInt32) async {
        // NOTE: Update the list first so that the opened mail disappears without waiting for the server.
        if mails.contains(where: { $0.uid == uid }) {
            mails.removeAll { $0.uid == uid }
            unreadCount = max(unreadCount - 1, 0)
            status = unreadCount > 0 ? .unread : .noUnread
        }

        do {
            try await api.markAsRead(uid)
        } catch {
            Logger.shared.error("failed to mark mail as read: \(error)")
        }
    }

    private func notify(_ newMails: Mails, email: String) {
        for mail in newMails {
            Task {
                await Notification.notify(
                    id: String(mail.uid),
                    uid: mail.uid,
                    title: mail.from,
                    body: mail.subject,
                    url: mail.url(email)
                )
            }
        }
    }
}
