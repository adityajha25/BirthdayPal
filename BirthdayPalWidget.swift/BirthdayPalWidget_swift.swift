//
//  BirthdayPalWidget.swift
//

import WidgetKit
import SwiftUI
import UIKit

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
        .widgetURL(entry.data.personDeepLinkURL)
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
        .widgetURL(entry.data.personDeepLinkURL)
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
                HStack(alignment: .top, spacing: 8) {
                    WidgetContactPhoto(data: entry.data.nextThumbnail, size: 32)
                    VStack(alignment: .leading, spacing: 4) {
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
                HStack(alignment: .center, spacing: 12) {
                    WidgetContactPhoto(data: entry.data.nextThumbnail, size: 48)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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

private struct WidgetContactPhoto: View {
    let data: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.15, green: 0.2, blue: 0.4))
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.42, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
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
