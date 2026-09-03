//
//  TransactionDayGroup.swift
//  SpendWise
//

import Foundation

/// A single calendar day's worth of transactions, grouped for display on
/// the Transactions screen's day-grouped list.
///
/// This is pure data — no SwiftUI, no `ModelContext` — so the grouping that
/// produces it (`makeGroups(from:in:)`) can be unit tested directly, per
/// this codebase's precedent of extracting pure computation out of the view
/// body (see `MonthKey`, `BudgetBar.cappedFraction(_:)`).
struct TransactionDayGroup: Identifiable {

    // MARK: - Properties

    /// The start-of-day `Date` this group represents. Used both as the
    /// group's stable identity and as the input to
    /// `DateLabelFormatter.dayHeader(for:)`.
    let date: Date

    /// Every transaction dated on `date`, in no particular guaranteed order
    /// beyond what `makeGroups(from:in:)` establishes (newest first).
    let transactions: [Transaction]

    // MARK: - Identifiable

    var id: Date { date }

    // MARK: - Derived

    /// The sum of every transaction's amount in this group, shown
    /// right-aligned next to the day header.
    var subtotal: Int {
        transactions.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Grouping

    /// Groups `transactions` by calendar day, keeping only those dated
    /// within `month`, for display on the Transactions screen.
    ///
    /// - Groups are ordered newest day first.
    /// - Within a group, transactions are ordered newest first.
    /// - A transaction's calendar day/month is determined by
    ///   `Calendar.current`, matching every other date computation in this
    ///   app (see `MonthKey`, `TransactionViewModel`'s aggregation helpers).
    static func makeGroups(from transactions: [Transaction], in month: MonthKey) -> [TransactionDayGroup] {
        let calendar = Calendar.current

        let monthTransactions = transactions.filter { MonthKey(date: $0.date, calendar: calendar) == month }
        let byDay = Dictionary(grouping: monthTransactions) { calendar.startOfDay(for: $0.date) }

        return byDay
            .map { day, transactions in
                TransactionDayGroup(date: day, transactions: transactions.sorted { $0.date > $1.date })
            }
            .sorted { $0.date > $1.date }
    }
}
