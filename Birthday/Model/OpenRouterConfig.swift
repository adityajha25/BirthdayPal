//
//  OpenRouterConfig.swift
//  Birthday
//
//  Client config for the Supabase Edge Function that proxies OpenRouter.
//  Never put OPENROUTER_API_KEY in the app — only the Supabase anon key.
//

import Foundation

/// Supabase project settings used to invoke `generate-birthday-message`.
///
/// Values are read from Info.plist:
/// - `SUPABASE_URL` — project root or full function URL, e.g.
///   `https://YOUR_PROJECT.supabase.co/functions/v1/generate-birthday-message`
/// - `SUPABASE_ANON_KEY` — Supabase anon (public) key from Project Settings → API
enum OpenRouterConfig {

    static let functionName = "generate-birthday-message"

    static var supabaseURLString: String {
        guard let fromPlist = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            return ""
        }
        return fromPlist.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var supabaseAnonKey: String {
        guard let fromPlist = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            return ""
        }
        return fromPlist.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var functionURL: URL? {
        guard isConfigured else { return nil }
        return Self.normalizedFunctionURL(from: supabaseURLString, functionName: functionName)
    }

    static var isConfigured: Bool {
        let url = supabaseURLString
        let key = supabaseAnonKey
        guard !url.isEmpty, !key.isEmpty else { return false }
        if url.contains("YOUR_PROJECT") { return false }
        if key.contains("YOUR_SUPABASE_ANON_KEY") { return false }
        return URL(string: url) != nil
    }

    static func normalizedFunctionURL(from raw: String, functionName: String) -> URL? {
        var base = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") {
            base.removeLast()
        }
        guard !base.isEmpty else { return nil }

        let functionSuffix = "/functions/v1/\(functionName)"
        if base.hasSuffix(functionSuffix) {
            return URL(string: base)
        }
        if base.hasSuffix("/functions/v1") {
            return URL(string: "\(base)/\(functionName)")
        }
        return URL(string: "\(base)\(functionSuffix)")
    }
}
