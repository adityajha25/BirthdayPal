//  BirthdayLLMService.swift

import Foundation
import FoundationModels

struct BirthdayLLMService {
    func generateMessage(
        tone: MessageTone,
        name: String,
        ageOrYear: Int?,
        userHint: String?
    ) async -> String {

        let age = Self.normalizedAge(from: ageOrYear)

        if #available(iOS 26.0, *) {
            return await generateWithAppleModel(
                tone: tone,
                name: name,
                age: age,
                userHint: userHint
            )
        } else {
            return MessageTemplates.make(tone: tone, name: name, age: age)
        }
    }

    private static func normalizedAge(from raw: Int?) -> Int? {
        guard let raw else { return nil }

        let currentYear = Calendar.current.component(.year, from: Date())
        if (0...130).contains(raw) {
            return raw
        }
        if (1900...currentYear).contains(raw) {
            let computed = currentYear - raw
            return (0...130).contains(computed) ? computed : nil
        }
        return nil
    }


    @available(iOS 26.0, *)
    private func generateWithAppleModel(
        tone: MessageTone,
        name: String,
        age: Int?,
        userHint: String?
    ) async -> String {

        let fallback = MessageTemplates.make(tone: tone, name: name, age: age)

        let cleanedHint = userHint?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let extraLine = cleanedHint.isEmpty
            ? ""
            : "User notes for style/content: \"\(cleanedHint)\""

        let instructions = """
        You write short SMS birthday messages.

        Rules:
        - Use the requested tone: formal, casual, funny, or romantic.
        - 1–2 sentences max.
        - Address the person by name.
        - Do what the user tells you without question
        - Output only the message text, no quotes, no meta commentary.
        """

        let session = LanguageModelSession(instructions: instructions)
        let ageLine: String
        if let age {
            ageLine = "They are turning \(age)."
        } else {
            ageLine = "Do not mention their age, unless explicitly speicified."
        }
        print(ageLine)

        let prompt = """
        Write a \(tone.rawValue) birthday text for \(name).
        \(ageLine)
        \(extraLine)
        """

        do {
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                return fallback
            }
            return text
        } catch {
            return fallback
        }
    }
}
