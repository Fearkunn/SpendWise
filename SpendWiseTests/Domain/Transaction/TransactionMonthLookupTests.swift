//
//  TransactionMonthLookupTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `TransactionMonthLookup.nearestEarlierMonthWithData(before:in:)`.
struct TransactionMonthLookupTests {

    @Test func returnsNilWhenNoTransactionsExist() {
        let result = TransactionMonthLookup.nearestEarlierMonthWithData(before: MonthKey(year: 2026, month: 9), in: [])
        #expect(result == nil)
    }

    @Test func returnsNilWhenEveryTransactionIsInOrAfterTheGivenMonth() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [
            Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 5)),
            Transaction(amount: 20_000, date: try date(year: 2026, month: 10, day: 1))
        ]

        let result = TransactionMonthLookup.nearestEarlierMonthWithData(before: september, in: transactions)

        #expect(result == nil)
    }

    @Test func returnsTheSingleEarlierMonthThatHasData() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [Transaction(amount: 10_000, date: try date(year: 2026, month: 7, day: 12))]

        let result = TransactionMonthLookup.nearestEarlierMonthWithData(before: september, in: transactions)

        #expect(result == MonthKey(year: 2026, month: 7))
    }

    @Test func returnsTheNearestOfSeveralEarlierMonthsWithData() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [
            Transaction(amount: 10_000, date: try date(year: 2026, month: 3, day: 1)),
            Transaction(amount: 20_000, date: try date(year: 2026, month: 7, day: 12)),
            Transaction(amount: 30_000, date: try date(year: 2025, month: 12, day: 25))
        ]

        let result = TransactionMonthLookup.nearestEarlierMonthWithData(before: september, in: transactions)

        #expect(result == MonthKey(year: 2026, month: 7))
    }

    @Test func excludesTransactionsInTheSameMonthAsTheGivenMonth() throws {
        let september = MonthKey(year: 2026, month: 9)
        let transactions = [Transaction(amount: 10_000, date: try date(year: 2026, month: 9, day: 1))]

        let result = TransactionMonthLookup.nearestEarlierMonthWithData(before: september, in: transactions)

        #expect(result == nil)
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return try #require(Calendar.current.date(from: components))
    }
}
