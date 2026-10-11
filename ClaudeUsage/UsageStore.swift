import Foundation
import Observation

@Observable
final class UsageStore {
    var session: UsageWindow?
    var weekly: UsageWindow?
    var errorMessage: String?

    /// On first launch the Help window is shown before the Keychain prompt appears.
    private(set) var hasSeenHelp = UserDefaults.standard.bool(forKey: "hasSeenHelp")
    @ObservationIgnored private var helpClosedContinuation: CheckedContinuation<Void, Never>?

    /// Call when the Help window closes; lets the first refresh (and Keychain prompt) start.
    func helpClosed() {
        guard !hasSeenHelp else { return }
        hasSeenHelp = true
        UserDefaults.standard.set(true, forKey: "hasSeenHelp")
        helpClosedContinuation?.resume()
        helpClosedContinuation = nil
    }

    /// Refreshes usage now and then every 5 minutes until the task is cancelled.
    /// Backs off to 15 minutes after the server rate-limits a request.
    func run() async {
        if !hasSeenHelp {
            await withCheckedContinuation { helpClosedContinuation = $0 }
        }
        while !Task.isCancelled {
            let delay = await refresh()
            try? await Task.sleep(for: delay)
        }
    }

    /// Fetches usage and returns how long to wait before the next refresh.
    func refresh() async -> Duration {
        do {
            let usage = try await UsageClient.fetchUsage()
            session = usage.fiveHour
            weekly = usage.sevenDay
            errorMessage = nil
        } catch UsageError.rateLimited {
            // Keep the last known numbers; just note why they aren't updating.
            errorMessage = UsageError.rateLimited.localizedDescription
            return .seconds(900)
        } catch {
            errorMessage = error.localizedDescription
        }
        return .seconds(300)
    }
}
