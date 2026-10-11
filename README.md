# Claude Usage

A tiny macOS menu bar app that shows your Claude plan usage — the same numbers as `/usage` in Claude Code.

```
✳ 42% · 18%
```

- **First number** – 5‑hour session limit
- **Second number** – weekly limit

Click it for reset times, Help, About and Quit. No windows, no settings, no Dock icon.

## Requirements

- macOS 15 Sequoia or later
- [Claude Code](https://claude.com/claude-code) installed and logged in with a Claude subscription (Pro / Max)

## How it works

1. Reads the OAuth token Claude Code stores in your login Keychain (`Claude Code-credentials`).
2. Calls `https://api.anthropic.com/api/oauth/usage` every 5 minutes (backs off to 15 minutes if rate‑limited).
3. Shows session and weekly utilization in the menu bar.

The app never refreshes the token itself, so it can't log Claude Code out. Checking usage doesn't consume tokens or count toward your limits.

> **Note:** the usage endpoint is not officially documented by Anthropic and may change or stop working.

## First launch

1. The Help window opens. Close it when you're ready.
2. macOS asks to allow access to the `Claude Code-credentials` Keychain item. Enter your Mac password and click **Always Allow**.
3. The usage appears in the menu bar.

## “Token expired”

Claude Code's token lasts a few hours and is refreshed only while Claude Code is in use. If the menu says *Token expired*:

1. Open Terminal and run `claude`
2. Send any message or type `/usage`
3. If you're not logged in, run `/login` first

The app picks up the new token within 5 minutes.

## Building from source

1. Clone the repository and open `ClaudeUsage.xcodeproj` in Xcode.
2. Select the **ClaudeUsage** target › **Signing & Capabilities** and choose your own team (and change the bundle identifier if needed).
3. Press **⌘R**.

The App Sandbox is disabled because a sandboxed app can't read another app's Keychain item. Hardened Runtime is enabled for notarization.

## Author

Nemanja Madžovski

## License

[MIT](LICENSE)
