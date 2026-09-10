//
//  AppConfig.swift
//  Mune
//
//  Created by Shehani Hansika on 12.05.26.
//


import Foundation

enum AppConfig {

    // MARK: - API Key
    // Used only when calling OpenAI directly (no proxy).
    // Leave empty once you deploy the Supabase proxy.
    static var apiKey: String {
        guard let rawKey = Bundle.main.object(forInfoDictionaryKey: "MYAPI_KEY") as? String else {
            MuneLog.debug("[AppConfig] Warning: MYAPI_KEY not found in Info.plist.")
            return ""
        }

        let key = rawKey
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !key.isEmpty,
              !key.contains("put-your-key-here"),
              !key.contains("$(MYAPI_KEY)") else {
            MuneLog.debug("[AppConfig] Warning: MYAPI_KEY is missing or invalid ('\(key)'). AI features will be unavailable.")
            return ""
        }

        return key
    }

    // MARK: - AI Endpoint
    // Cloudflare Worker name must match this hostname (mune-openai-proxy).
    static let proxyURL: String? = "https://mune-openai-proxy.shehani1207.workers.dev"

    /// Inbox that receives in-app feedback.
    static let feedbackEmail = "shehani1207@gmail.com"

    /// Local notification identifier. Must not contain leftover brand names.
    static let dailyReminderIdentifier = "mune.daily.reminder"

    /// Full chat-completions URL the service will call.
    static var chatEndpointURL: String {
        proxyURL ?? "https://api.openai.com/v1/chat/completions"
    }

    /// When a proxy handles auth, no key is forwarded from the app.
    static var useDirectAuth: Bool { proxyURL == nil }
}