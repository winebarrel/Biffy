import SwiftUI

struct RightClickMenuView: View {
    @AppStorage("email") private var email = ""

    var body: some View {
        Button("Open Gmail") {
            NSWorkspace.shared.open(URL(string: "https://mail.google.com/mail/?authuser=\(email)#inbox")!)
        }
        Divider()
        SettingsLink {
            Text("Settings")
        }.preActionButtonStyle {
            NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(self)
        }
    }
}
