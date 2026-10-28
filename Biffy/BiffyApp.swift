import AsyncAlgorithms
import MenuBarExtraAccess
import SwiftUI

@main
struct BiffyApp: App {
    @State private var initialized = false
    @State private var isMenuPresented = false
    @State private var timer: Task<Void, Never>?
    @State private var clickHandler: StatusItemClickHandler?
    // NOTE: Define "appPassword" in BiffyApp so that values are not lost during sleep.
    @State private var appPassword = Vault.appPassword
    @AppStorage("email") private var email = ""
    @AppStorage("interval") private var interval = Constants.defaultInterval
    @StateObject private var gmail = GmailModel()

    // swiftlint:disable unused_declaration
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // swiftlint:enable unused_declaration

    private var popover = {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = false
        pop.contentSize = NSSize(width: 500, height: 400)
        return pop
    }()

    private func initialize() {
        let contentView = ContentView(gmail: gmail, email: $email, appPassword: $appPassword)
        popover.contentViewController = NSHostingController(rootView: contentView)

        appDelegate.onOpenMail = { uid in
            Task {
                await gmail.markAsRead(GmailAPI(email: email, appPassword: appPassword), uid: uid)
            }
        }

        scheduleUpdate()
    }

    private func scheduleUpdate() {
        timer?.cancel()

        let seq = AsyncTimerSequence(
            interval: .seconds(max(interval, Constants.minInterval)),
            clock: .continuous
        )

        timer = Task {
            let api = GmailAPI(email: email, appPassword: appPassword)
            await gmail.update(api)

            for await _ in seq {
                await gmail.update(api)
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            RightClickMenuView()
        } label: {
            Image(systemName: gmail.status.rawValue).onAppear {
                if !initialized {
                    initialize()
                    initialized = true
                }
            }
        }.menuBarExtraAccess(isPresented: $isMenuPresented) { statusItem in
            guard clickHandler == nil, let button = statusItem.button else { return }
            let handler = StatusItemClickHandler(statusItem: statusItem)

            handler.onLeftClick = {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.maxY)
                    popover.contentViewController?.view.window?.makeKey()
                }
            }

            clickHandler = handler
        }
        Settings {
            SettingView(appPassword: $appPassword)
                .onClosed {
                    scheduleUpdate()
                }
        }
    }
}
