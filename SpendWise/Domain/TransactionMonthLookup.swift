//
//  TransactionMonthLookup.swift
//  SpendWise
//

import Foundation

/// Finds the nearest earlier calendar month that actually contains
/// transaction data, powering the Transactions screen's
/// jump-to-previous-month pill (shown only when such a month exists) and
/// its month-empty state's conditional copy.
enum TransactionMonthLookup {

    // MARK: - Methods

    /// The most recent calendar month strictly before `month` that contains
    /// at least one of `transactions`, or `nil` if none exists.
    ///
    /// "Strictly before" is measured by `MonthKey`'s own `Comparable`
    /// ordering (year, then month) — a transaction dated *after* `month` is
    /// never returned, even if `transactions` otherwise has entries.
    static func nearestEarlierMonthWithData(before month: MonthKey, in transactions: [Transaction]) -> MonthKey? {
        transactions
            .map { MonthKey(date: $0.date) }
            .filter { $0 < month }
            .max()
    }
}
