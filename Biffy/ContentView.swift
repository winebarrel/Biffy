import SwiftUI

struct ContentView: View {
    @ObservedObject var gmail: GmailModel
    @Binding var email: String
    @Binding var appPassword: String
    @State private var hoverId: UInt32?

    var body: some View {
        VStack {
            if email.isEmpty || appPassword.isEmpty {
                List {
                    VStack {
                        Spacer().padding()
                        Image(nsImage: NSApp.applicationIconImage)
                        Link(destination: URL(string: "https://github.com/winebarrel/Biffy#configuration")!) {
                            Text("Set up your Gmail address and app password.")
                        }.effectHoverCursor()
                        HStack {
                            Spacer()
                            SettingsLink {
                                Image(systemName: "gearshape")
                                Text("Settings")
                            }.preActionButtonStyle {
                                NSApp.activate(ignoringOtherApps: true)
                            }
                            Spacer()
                        }
                    }
                }
            } else if let err = gmail.error {
                List {
                    HStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .imageScale(.large)
                        Text(err.localizedDescription)
                        Spacer()
                    }
                }
            } else if gmail.mails.isEmpty {
                List {
                    HStack {
                        Spacer()
                        Image(systemName: "face.smiling")
                            .imageScale(.large)
                        Text("No Unread Mail")
                        Spacer()
                    }
                }
            } else {
                List(gmail.mails) { mail in
                    VStack(alignment: .leading) {
                        Text(mail.from)
                            .font(.caption)
                            .fontWeight(.bold)

                        HStack {
                            Link(destination: URL(string: mail.url(email))!) {
                                Text(mail.subject.isEmpty ? "(no subject)" : mail.subject)
                                    .multilineTextAlignment(.leading)
                                    .underline(hoverId == mail.id)
                            }
                            // NOTE: Since macOS 27, onHover inside a Link label is never called,
                            // so handle hover on the Link itself.
                            .onHover { hovering in
                                hoverId = hovering ? mail.id : nil
                            }
                            .effectHoverCursor()
                            .environment(\.openURL, OpenURLAction { _ in
                                Task {
                                    await gmail.markAsRead(GmailAPI(email: email, appPassword: appPassword), uid: mail.uid)
                                }
                                return .systemAction
                            })
                            Text("(\(mail.date.relative()))").font(.caption2)
                        }
                    }
                }
            }
            HStack {
                Button {
                    Task {
                        await gmail.update(GmailAPI(email: email, appPassword: appPassword))
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }.effectHoverCursor()

                let label = if let updatedAt = gmail.updatedAt {
                    updatedAt.shortTime()
                } else {
                    "-"
                }

                Text(label)

                if gmail.unreadCount > gmail.mails.count {
                    Text("(\(gmail.mails.count) of \(gmail.unreadCount) unread)")
                        .font(.caption)
                }
            }
            .padding(.bottom, 5)
        }
    }
}

#Preview {
    ContentView(
        gmail: GmailModel(),
        email: .constant(""),
        appPassword: .constant("")
    )
}
