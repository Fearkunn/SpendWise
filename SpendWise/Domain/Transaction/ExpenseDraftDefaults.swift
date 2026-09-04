//
//  ExpenseDraftDefaults.swift
//  SpendWise
//

import Foundation

/// Default values for a brand-new expense draft on the add/edit sheet (#13).
enum ExpenseDraftDefaults {

    // MARK: - Default Date

    /// A new expense's default date: today when the current month is
    /// selected, otherwise the last day of the selected month — so the new
    /// expense lands inside the month being viewed rather than immediately
    /// vanishing from the filtered list the moment it's saved.
    ///
    /// - Parameters:
    ///   - selectedMonth: The shared month currently being viewed on the
    ///     Transactions screen.
    ///   - today: The date "today" is measured against. Defaults to now;
    ///     overridable for testing.
    static func date(selectedMonth: MonthKey, today: Date = .now) -> Date {
        selectedMonth == MonthKey(date: today) ? today : selectedMonth.lastDayOfMonth
    }
}
