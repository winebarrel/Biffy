import AppKit
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var onOpenMail: ((UInt32) -> Void)?

    func applicationDidFinishLaunching(_: Foundation.Notification) {
        UNUserNotificationCenter.current().delegate = self

        Task {
            do {
                let center = UNUserNotificationCenter.current()

                guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                    Logger.shared.warning("user notification not authorized")
                    return
                }
            } catch {
                Logger.shared.error("user notification authorization request error: \(error)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        guard let url = userInfo["url"] as? String else {
            fatalError("failed to cast userInfo['url'] to String")
        }

        NSWorkspace.shared.open(URL(string: url)!)

        if let uid = userInfo["uid"] as? Int {
            Task { @MainActor in
                self.onOpenMail?(UInt32(uid))
            }
        }

        completionHandler()
    }
}
