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
/// Fill the placeholders below, **or** set Info.plist / xcconfig keys:
/// - `SUPABASE_URL` — project root **or** full function URL (either works):
///   - `https://YOUR_PROJECT.supabase.co`
///   - `https://YOUR_PROJECT.supabase.co/functions/v1/generate-birthday-message`
/// - `SUPABASE_ANON_KEY` — project anon (public) key
enum OpenRouterConfig {

    /// Fallback when Info.plist has no `SUPABASE_URL`.
    /// Accepts project root or the full Edge Function invoke URL.
    private static let placeholderURL = "https://khanavjbozyavakkndvr.supabase.co/functions/v1/generate-birthday-message"

    /// Fallback when Info.plist has no `SUPABASE_ANON_KEY`.
    private static let placeholderAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtoYW5hdmpib3p5YXZha2tuZHZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2MzQ3MzQsImV4cCI6MjEwMTIxMDczNH0.rjFRk19Jh0I4kEViOYOgHgJMYZKRa71d2gWZItbcTtI"

    /// Function path under `/functions/v1/`.
    static let functionName = "generate-birthday-message"

    static var supabaseURLString: String {
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           !fromPlist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromPlist.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return placeholderURL
    }

    static var supabaseAnonKey: String {
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !fromPlist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fromPlist.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return placeholderAnonKey
    }

    /// `https://<project>.supabase.co/functions/v1/generate-birthday-message`
    ///
    /// Normalizes project root, `/functions/v1`, or a full function URL so the
    /// path is never doubled.
    static var functionURL: URL? {
        guard isConfigured else { return nil }
        return Self.normalizedFunctionURL(from: supabaseURLString, functionName: functionName)
    }

    /// True when URL and anon key look filled in (not the shipped placeholders).
    static var isConfigured: Bool {
        let url = supabaseURLString
        let key = supabaseAnonKey
        guard !url.isEmpty, !key.isEmpty else { return false }
        if url.contains("YOUR_PROJECT") { return false }
        if key.contains("YOUR_SUPABASE_ANON_KEY") { return false }
        return URL(string: url) != nil
    }

    /// Builds the invoke URL from a project root, functions base, or full function URL.
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
