import SwiftUI

@main struct MyApp: App {
    @State private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            UsageMenu(store: store)
        } label: {
            // The label is always rendered, so polling starts at launch.
            Label(labelText, systemImage: "sparkle")
                .labelStyle(.titleAndIcon)
                .monospacedDigit()
                .task { await store.run() }
        }

        Window("Help", id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.suppressed)
    }

    private var labelText: String {
        guard let session = store.session, let weekly = store.weekly else { return "–" }
        return "\(Int(session.utilization.rounded()))% · \(Int(weekly.utilization.rounded()))%"
    }
}

struct UsageMenu: View {
    let store: UsageStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(line("Session", store.session, relative: true))
        Text(line("Weekly", store.weekly, relative: false))
        if let error = store.errorMessage {
            Text(error)
        }
        Divider()
        Button("Help") {
            NSApplication.shared.activate()
            openWindow(id: "help")
        }
        Button("About") { showAbout() }
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    /// Standard About panel (icon, name, version) with the author as credits.
    private func showAbout() {
        let credits = NSAttributedString(
            string: "Author: Nemanja Madžovski",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        // Menu bar apps aren't active by default, so bring the panel to the front.
        NSApplication.shared.activate()
        NSApplication.shared.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    private func line(_ title: String, _ window: UsageWindow?, relative: Bool) -> String {
        guard let window else { return "\(title): –" }
        var text = "\(title): \(Int(window.utilization.rounded()))%"
        if let reset = window.resetDate {
            let when = relative
                ? "in " + Duration.seconds(max(0, reset.timeIntervalSinceNow))
                    .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
                : reset.formatted(.dateTime.weekday(.abbreviated).hour().minute())
            text += " · resets \(when)"
        }
        return text
    }
}
