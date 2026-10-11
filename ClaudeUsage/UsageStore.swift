import Foundation
import Observation

@Observable
final class UsageStore {
    var session: UsageWindow?
    var weekly: UsageWindow?
    var errorMessage: String?

    /// Refreshes usage now and then every 5 minutes until the task is cancelled.
    func run() async {
        while !Task.isCancelled {
            await refresh()
            try? await Task.sleep(for: .seconds(300))
        }
    }

    func refresh() async {
        print("[Usage] refresh started")
        do {
            let usage = try await UsageClient.fetchUsage()
            session = usage.fiveHour
            weekly = usage.sevenDay
            errorMessage = nil
        } catch {
            print("[Usage] error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
