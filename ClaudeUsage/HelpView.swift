import SwiftUI

/// Small fixed-size help window, styled like the standard About panel.
struct HelpView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("Help")
                .font(.headline)

            Text("Usage comes from your Claude Code login.")
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("When macOS asks for Keychain access:")
                    .fontWeight(.medium)
                Text("Enter your Mac password and click **Always Allow**, so the app can read your Claude Code login without asking again.")
                    .fixedSize(horizontal: false, vertical: true)
                Text("It may ask once more after the app is updated.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("If it says “Token expired”:")
                    .fontWeight(.medium)
                Text("1. Open Terminal and run `claude`")
                Text("2. Send any message or type `/usage`")
                Text("3. If not logged in, run `/login` first")
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Numbers update every minute. Tokens last a few hours — use Claude Code in Terminal to keep them fresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 300)
    }
}

#Preview {
    HelpView()
}
