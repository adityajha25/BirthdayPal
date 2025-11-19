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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text("Birthdays Remembered")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(entry.data.rememberedCount)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.cyan)
                Text("this year")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            if entry.data.rememberedCount == 0 {
                Text("Start sending messages 🎉")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } else if entry.data.rememberedCount < 10 {
                Text("Nice start – keep going! 🎂")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text("You're a birthday pro 🥳")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.12, blue: 0.28)
        }
    }
}

// MARK: - View 2: Upcoming birthday

struct UpcomingBirthdayWidgetView: View {
    var entry: BirthdayWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("🎂")
                    .font(.caption)
                Text("Upcoming Birthday")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }

            if let name = entry.data.nextName,
               let days = entry.data.daysToNext {
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        if days == 0 {
                            Image(systemName: "party.popper.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("Today!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.cyan)
                                .font(.caption2)
                            Text("In \(days) day\(days == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.6))
                    )
                }
            } else {
                Text("No upcoming birthdays")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Text("\(entry.data.upcomingThisMonth) this month")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.12, blue: 0.28)
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
