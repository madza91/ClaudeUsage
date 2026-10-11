import Foundation
import Security

/// One usage window (5-hour session or 7-day) as reported by the OAuth usage endpoint.
nonisolated struct UsageWindow: Decodable, Sendable {
    /// Percentage of the limit used, 0–100.
    let utilization: Double
    let resetsAt: String?

    var resetDate: Date? {
        guard let resetsAt else { return nil }
        let withFraction = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        return (try? withFraction.parse(resetsAt)) ?? (try? Date.ISO8601FormatStyle().parse(resetsAt))
    }
}

nonisolated struct UsageResponse: Decodable, Sendable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
}

nonisolated enum UsageError: LocalizedError {
    case notLoggedIn
    case tokenExpired
    case rateLimited
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn: "Not logged in to Claude Code"
        case .tokenExpired: "Token expired — run Claude Code"
        case .rateLimited: "Too many requests — retrying in 5 min"
        case .badResponse(let code): "Usage request failed (HTTP \(code))"
        }
    }
}

/// Reads Claude Code's OAuth token from the Keychain and fetches plan usage.
nonisolated enum UsageClient {
    private struct Credentials: Decodable {
        struct OAuth: Decodable {
            let accessToken: String
            /// Milliseconds since 1970.
            let expiresAt: Double?
        }
        let claudeAiOauth: OAuth
    }

    /// Claude Code stores its credentials as JSON in this generic password item.
    static func readAccessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONDecoder().decode(Credentials.self, from: data)
        else { throw UsageError.notLoggedIn }

        let oauth = credentials.claudeAiOauth
        if let expiresAt = oauth.expiresAt, Date(timeIntervalSince1970: expiresAt / 1000) < .now {
            throw UsageError.tokenExpired
        }
        return oauth.accessToken
    }

    static func fetchUsage() async throws -> UsageResponse {
        let token = try readAccessToken()
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            throw UsageError.badResponse(0)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw UsageError.tokenExpired }
        if status == 429 { throw UsageError.rateLimited }
        guard status == 200 else { throw UsageError.badResponse(status) }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UsageResponse.self, from: data)
    }
}
