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
    @Environment(\.widgetFamily) private var family
    var entry: BirthdayWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            Label(
                family == .systemSmall ? "Remembered" : "Birthdays Remembered",
                systemImage: "sparkles"
            )
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.8))
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.85)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(entry.data.rememberedCount)")
                    .font(.system(size: family == .systemSmall ? 36 : 44, weight: .bold))
                    .foregroundColor(.cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("this year")
                    .font(family == .systemSmall ? .caption : .subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(footerCopy)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(family == .systemSmall ? 12 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.12, blue: 0.28)
        }
    }

    private var footerCopy: String {
        if entry.data.rememberedCount == 0 {
            return "Send a birthday message"
        } else if entry.data.rememberedCount < 10 {
            return "Nice start — keep going"
        } else {
            return "You're a birthday pro"
        }
    }
}

// MARK: - View 2: Upcoming birthday

struct UpcomingBirthdayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: BirthdayWidgetEntry

    var body: some View {
        Group {
            if family == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.12, blue: 0.28)
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Upcoming", systemImage: "birthday.cake.fill")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)

            if let name = entry.data.nextName,
               let days = entry.data.daysToNext {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Text(daysLabel(days))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(days == 0 ? .yellow : .cyan)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            } else {
                Text("No upcoming birthdays")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text("\(entry.data.upcomingThisMonth) this month")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .padding(12)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Upcoming Birthday", systemImage: "birthday.cake.fill")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .labelStyle(.titleAndIcon)
                .lineLimit(1)

            if let name = entry.data.nextName,
               let days = entry.data.daysToNext {
                VStack(alignment: .leading, spacing: 8) {
                    Text(name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(daysLabel(days))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(days == 0 ? .yellow : .white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.12, green: 0.16, blue: 0.35).opacity(0.6))
                        )
                        .lineLimit(1)
                }
            } else {
                Text("No upcoming birthdays")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Text("\(entry.data.upcomingThisMonth) this month")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .padding(16)
    }

    private func daysLabel(_ days: Int) -> String {
        if days == 0 { return "Today!" }
        if days == 1 { return "In 1 day" }
        return "In \(days) days"
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
