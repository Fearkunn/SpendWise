//
//  ExpenseDateChip.swift
//  SpendWise
//

import Foundation

/// One of the three quick-select date chips shown under the expense sheet's
/// date field.
///
/// Which three chips appear, and what they mean, depends entirely on
/// whether the *shared selected month* (not the draft's own date) is the
/// current calendar month — matching the mockup's `dateChips` derivation,
/// which reads `s.sel` (the shared month), not the in-progress draft:
/// - Viewing the current month: `Today` / `Yesterday` / `End of [previous month]`.
/// - Viewing any other month: `First of [month]` / `Last of [month]` / `Today`.
struct ExpenseDateChip: Identifiable, Equatable {

    // MARK: - Properties

    let id: String
    let label: String
    let date: Date

    // MARK: - Quick-Select Chips

    /// The three quick-select chips for the given shared selected month.
    ///
    /// - Parameters:
    ///   - selectedMonth: The shared month currently being viewed on the
    ///     Transactions screen — not the sheet's in-progress draft date.
    ///   - today: The date "today" is measured against. Defaults to now;
    ///     overridable for testing.
    ///   - calendar: The calendar used for month/day arithmetic. Defaults
    ///     to the device's current calendar; overridable for testing.
    static func quickSelectChips(selectedMonth: MonthKey, today: Date = .now, calendar: Calendar = .current) -> [ExpenseDateChip] {
        let startOfToday = calendar.startOfDay(for: today)

        guard selectedMonth == MonthKey(date: today, calendar: calendar) else {
            return [
                ExpenseDateChip(id: "firstOfMonth", label: "First of \(selectedMonth.monthAbbreviation)", date: selectedMonth.startOfMonth),
                ExpenseDateChip(id: "lastOfMonth", label: "Last of \(selectedMonth.monthAbbreviation)", date: selectedMonth.lastDayOfMonth),
                ExpenseDateChip(id: "today", label: "Today", date: startOfToday)
            ]
        }

        // Safe: subtracting a day from a real `Date` cannot fail; `??
        // startOfToday` only exists to satisfy the optional-to-non-optional
        // conversion and is never actually exercised.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let previousMonth = selectedMonth.previous()

        return [
            ExpenseDateChip(id: "today", label: "Today", date: startOfToday),
            ExpenseDateChip(id: "yesterday", label: "Yesterday", date: yesterday),
            ExpenseDateChip(id: "endOfPreviousMonth", label: "End of \(previousMonth.monthAbbreviation)", date: previousMonth.lastDayOfMonth)
        ]
    }
}
