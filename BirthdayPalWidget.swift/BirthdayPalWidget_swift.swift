//
//  BirthdayPalWidget.swift
//

import WidgetKit
import SwiftUI

// MARK: - Timeline entry

struct BirthdayWidgetEntry: TimelineEntry {
    let date: Date
    let data: BirthdayWidgetData
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayWidgetEntry {
        BirthdayWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (BirthdayWidgetEntry) -> Void) {
        let shared = BirthdayWidgetData.loadFromShared()
        completion(BirthdayWidgetEntry(date: Date(), data: shared))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<BirthdayWidgetEntry>) -> Void) {
        let shared = BirthdayWidgetData.loadFromShared()
        let entry = BirthdayWidgetEntry(date: Date(), data: shared)

        // Refresh ~every 30 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())
            ?? Date().addingTimeInterval(60 * 30)

        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

// MARK: - View 1: Remembered birthdays

struct RememberedBirthdaysWidgetView: View {
    var entry: BirthdayWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Birthdays remembered")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(entry.data.rememberedCount)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                Text("this year")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }

            Spacer()

            if entry.data.rememberedCount == 0 {
                Text("Start sending birthday messages 🎉")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else if entry.data.rememberedCount < 10 {
                Text("Nice start – keep going! 🎂")
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                Text("You're a birthday pro 🥳")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        // 👇 This is what fixes the “please adopt containerBackground” warning
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

// MARK: - View 2: Upcoming birthday

struct UpcomingBirthdayWidgetView: View {
    var entry: BirthdayWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🎂 Upcoming birthday")
                .font(.caption)
                .foregroundColor(.gray)

            if let name = entry.data.nextName,
               let days = entry.data.daysToNext {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(days == 0 ? "Today 🎉"
                               : "In \(days) day\(days == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.white)
            } else {
                Text("No upcoming birthdays")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Spacer()

            Text("\(entry.data.upcomingThisMonth) this month")
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

// MARK: - Widget 1: Remembered

struct RememberedBirthdaysWidget: Widget {
    let kind: String = "RememberedBirthdaysWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RememberedBirthdaysWidgetView(entry: entry)
        }
        .configurationDisplayName("Birthdays Remembered")
        .description("Shows how many birthdays you've remembered.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget 2: Upcoming

struct UpcomingBirthdayWidget: Widget {
    let kind: String = "UpcomingBirthdayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            UpcomingBirthdayWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Birthday")
        .description("Shows the next upcoming birthday.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

