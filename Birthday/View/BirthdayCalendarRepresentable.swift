//
//  BirthdayCalendarRepresentable.swift
//  Birthday
//

import SwiftUI
import UIKit

/// UICalendarView wrapper that draws dots on days with birthdays.
@available(iOS 17.0, *)
struct BirthdayCalendarRepresentable: UIViewRepresentable {
    @Binding var selectedDate: Date
    var contactsVM: ContactViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.delegate = context.coordinator
        calendarView.calendar = Calendar.current
        calendarView.locale = .current
        calendarView.tintColor = .systemCyan
        calendarView.overrideUserInterfaceStyle = .dark

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        selection.setSelected(
            Calendar.current.dateComponents([.year, .month, .day], from: selectedDate),
            animated: false
        )

        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self
        // Refresh decorations for the visible month around the selected date
        let comps = monthDateComponents(around: selectedDate)
        uiView.reloadDecorations(forDateComponents: comps, animated: false)
    }

    private func monthDateComponents(around date: Date) -> [DateComponents] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: date) else { return [] }
        var result: [DateComponents] = []
        var day = interval.start
        while day < interval.end {
            result.append(calendar.dateComponents([.year, .month, .day], from: day))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: BirthdayCalendarRepresentable

        init(_ parent: BirthdayCalendarRepresentable) {
            self.parent = parent
        }

        func calendarView(
            _ calendarView: UICalendarView,
            decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            guard parent.contactsVM.hasBirthday(on: dateComponents) else { return nil }
            return .default(color: .systemCyan, size: .small)
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            guard let dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            parent.selectedDate = date
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            canSelectDate dateComponents: DateComponents?
        ) -> Bool {
            true
        }
    }
}
