//
//  TransactionDayGroupTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `TransactionDayGroup.makeGroups(from:in:)`: filtering to the
/// target month, grouping by calendar day, per-day subtotals, and ordering.
struct TransactionDayGroupTests {

    // MARK: - Filtering

    @Test func excludesTransactionsOutsideTheTargetMonth() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [
            Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 5)),
            Transaction(amount: 20_000, date: try date(year: 2026, month: 8, day: 31)),
            Transaction(amount: 30_000, date: try date(year: 2026, month: 10, day: 1))
        ]

        let groups = TransactionDayGroup.makeGroups(from: transactions, in: september)

        #expect(groups.count == 1)
        #expect(groups.first?.transactions.count == 1)
        #expect(groups.first?.subtotal == 10_000)
    }

    // MARK: - Grouping By Day

    @Test func groupsTransactionsOnTheSameCalendarDayTogether() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [
            Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 5, hour: 8)),
            Transaction(amount: 20_000, date: try date(year: 2026, month: 9, day: 5, hour: 18)),
            Transaction(amount: 30_000, date: try date(year: 2026, month: 9, day: 6, hour: 9))
        ]

        let groups = TransactionDayGroup.makeGroups(from: transactions, in: september)

        #expect(groups.count == 2)
    }

    @Test func subtotalSumsOnlyThatDaysTransactions() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [
            Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 5, hour: 8)),
            Transaction(amount: 20_000, date: try date(year: 2026, month: 9, day: 5, hour: 18)),
            Transaction(amount: 30_000, date: try date(year: 2026, month: 9, day: 6, hour: 9))
        ]

        let groups = TransactionDayGroup.makeGroups(from: transactions, in: september)
        let fifthGroup = try #require(groups.first { Calendar.current.component(.day, from: $0.date) == 5 })

        #expect(fifthGroup.subtotal == 30_000)
    }

    // MARK: - Ordering

    @Test func ordersGroupsNewestDayFirst() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [
            Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 1)),
            Transaction(amount: 20_000, date: try date(year: 2026, month: 9, day: 15)),
            Transaction(amount: 30_000, date: try date(year: 2026, month: 9, day: 30))
        ]

        let groups = TransactionDayGroup.makeGroups(from: transactions, in: september)
        let days = groups.map { Calendar.current.component(.day, from: $0.date) }

        #expect(days == [30, 15, 1])
    }

    @Test func ordersTransactionsWithinADayNewestFirst() throws {
        let september = MonthKey(year: 2026, month: 9)
        let earlier = Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 5, hour: 8))
        let later = Transaction(amount: 20_000, date: try date(year: 2026, month: 9, day: 5, hour: 18))

        let groups = TransactionDayGroup.makeGroups(from: [earlier, later], in: september)
        let ordered = try #require(groups.first).transactions

        #expect(ordered.map(\.amount) == [20_000, 10_000])
    }

    // MARK: - Empty Input

    @Test func returnsNoGroupsWhenNoTransactionsFallInTheMonth() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [Transaction(amount: 10_000, date: try date(year: 2026, month: 8, day: 1))]

        let groups = TransactionDayGroup.makeGroups(from: transactions, in: september)

        #expect(groups.isEmpty)
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int, hour: Int = 12) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return try #require(Calendar.current.date(from: components))
    }
}
