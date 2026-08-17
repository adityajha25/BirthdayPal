//
//  BirthdayCalendarRepresentable.swift
//  Birthday
//

import SwiftUI
import UIKit

/// UICalendarView wrapper that draws dots on days with birthdays.
/// Hosted in a container so intrinsic size cannot blow past screen width inside ScrollView.
struct BirthdayCalendarRepresentable: UIViewRepresentable {
    @Binding var selectedDate: Date
    var contactsVM: ContactViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        container.clipsToBounds = true

        let calendarView = UICalendarView()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.delegate = context.coordinator
        calendarView.calendar = Calendar.current
        calendarView.locale = .current
        calendarView.tintColor = .systemCyan
        calendarView.overrideUserInterfaceStyle = .dark
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        calendarView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        selection.setSelected(
            Calendar.current.dateComponents([.year, .month, .day], from: selectedDate),
            animated: false
        )

        container.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: container.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.calendarView = calendarView
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        guard let calendarView = context.coordinator.calendarView else { return }
        let comps = monthDateComponents(around: selectedDate)
        calendarView.reloadDecorations(forDateComponents: comps, animated: false)

        if let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            let selected = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            if selection.selectedDate != selected {
                selection.setSelected(selected, animated: false)
            }
        }
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
        weak var calendarView: UICalendarView?

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
