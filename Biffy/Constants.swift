import Foundation

enum Constants {
    static let defaultInterval: TimeInterval = 60
    /// Gmail may throttle frequent IMAP logins, so keep the interval from being too short.
    static let minInterval: TimeInterval = 30
    static let maxMails = 50
}
