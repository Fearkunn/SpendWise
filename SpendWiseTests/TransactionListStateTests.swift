//
//  TransactionListStateTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `TransactionListState.determine(...)` — the pure decision logic
/// behind which of the Transactions screen's three list states applies.
struct TransactionListStateTests {

    @Test func noExpensesAtAllWhenTotalCountIsZero() {
        let state = TransactionListState.determine(
            totalTransactionCount: 0,
            monthTransactionCount: 0,
            hasEarlierMonthWithData: false
        )

        #expect(state == .noExpensesAtAll)
    }

    @Test func monthEmptyWhenTotalCountIsPositiveButMonthCountIsZero() {
        let state = TransactionListState.determine(
            totalTransactionCount: 5,
            monthTransactionCount: 0,
            hasEarlierMonthWithData: true
        )

        #expect(state == .monthEmpty(hasEarlierMonthWithData: true))
    }

    @Test func monthEmptyCarriesThroughFalseWhenNoEarlierMonthHasData() {
        let state = TransactionListState.determine(
            totalTransactionCount: 5,
            monthTransactionCount: 0,
            hasEarlierMonthWithData: false
        )

        #expect(state == .monthEmpty(hasEarlierMonthWithData: false))
    }

    @Test func populatedWhenMonthCountIsPositive() {
        let state = TransactionListState.determine(
            totalTransactionCount: 5,
            monthTransactionCount: 2,
            hasEarlierMonthWithData: false
        )

        #expect(state == .populated)
    }

    @Test func noExpensesAtAllTakesPriorityOverMonthEmptyWhenBothCountsAreZero() {
        // A total count of 0 necessarily implies a month count of 0 too, but
        // this asserts the priority explicitly rather than leaving it
        // implicit in `determine`'s branch order.
        let state = TransactionListState.determine(
            totalTransactionCount: 0,
            monthTransactionCount: 0,
            hasEarlierMonthWithData: true
        )

        #expect(state == .noExpensesAtAll)
    }
}
