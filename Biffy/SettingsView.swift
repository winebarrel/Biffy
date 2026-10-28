import ServiceManagement
import SwiftUI

struct SettingView: View {
    @Binding var appPassword: String
    @AppStorage("email") private var email = ""
    @AppStorage("interval") private var interval = Constants.defaultInterval
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            TextField("Gmail Address", text: $email)
                .onChange(of: email) {
                    email = email.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            SecureField(text: $appPassword) {
                Link("App Password", destination: URL(string: "https://myaccount.google.com/apppasswords")!)
                    .effectHoverCursor()
            }.onChange(of: appPassword) {
                // NOTE: Google shows app passwords in groups of four separated by spaces.
                appPassword = appPassword.filter { !$0.isWhitespace }
                Vault.appPassword = appPassword
            }
            TextField("Interval (sec)", value: $interval, format: .number.grouping(.never))
                .onChange(of: interval) {
                    if interval < Constants.minInterval {
                        interval = Constants.minInterval
                    } else if interval > 3600 {
                        interval = 3600
                    }
                }
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) {
                    do {
                        if launchAtLogin {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        Logger.shared.error("failed to update 'Launch at login': \(error)")
                    }
                }
            HStack {
                // swiftlint:disable force_cast
                let appVer = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                // swiftlint:enable force_cast
                Text("Version. \(appVer)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Link(destination: URL(string: "https://github.com/winebarrel/Biffy")!) {
                    Image("github-mark")
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .effectHoverCursor()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(width: 400)
    }

    func onClosed(_ action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
            if let window = notification.object as? NSWindow, window.title == "Biffy Settings" {
                action()
            }
        }
    }
}

#Preview {
    SettingView(appPassword: .constant(""))
}
