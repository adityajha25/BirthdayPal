//
//  BirthdayPalWidget_swiftControl.swift
//  BirthdayPalWidget.swift
//
//  Control Center button — opens BirthdayPal to today's birthdays.
//

import AppIntents
import SwiftUI
import WidgetKit

/// Control Center control that jumps into BirthdayPal's "Today's Birthdays" screen.
struct TodaysBirthdaysControl: ControlWidget {
    static let kind = "IOSAppClub.Birthday.TodaysBirthdaysControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTodaysBirthdaysIntent()) {
                Label("Today's Birthdays", systemImage: "birthday.cake.fill")
            }
        }
        .displayName("Today's Birthdays")
        .description("Open BirthdayPal to see who has a birthday today.")
    }
}

/// Opens the main app and deep-links to today's birthdays.
struct OpenTodaysBirthdaysIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Birthdays"
    static let description = IntentDescription("Open BirthdayPal to today's birthdays.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        DeepLink.setPending(.todaysBirthdays)
        return .result()
    }
}
