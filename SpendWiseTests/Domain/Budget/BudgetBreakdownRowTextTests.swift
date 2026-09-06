//
//  BudgetBreakdownRowTextTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `BudgetBreakdownRowText.statusText(status:limit:spent:)` and
/// `.limitText(limit:)`.
struct BudgetBreakdownRowTextTests {

    // MARK: - Status Text: Over

    @Test func statusTextOverReadsAmountOverAndPercent() {
        let text = BudgetBreakdownRowText.statusText(status: .over, limit: 800_000, spent: 950_000)
        #expect(text == "Rp150.000 OVER · 119%")
    }

    // MARK: - Status Text: At Limit

    @Test func statusTextAtLimitReadsAtLimitAndHundredPercent() {
        let text = BudgetBreakdownRowText.statusText(status: .atLimit, limit: 500_000, spent: 500_000)
        #expect(text == "AT LIMIT · 100%")
    }

    // MARK: - Status Text: Under, Zero Spend

    @Test func statusTextUnderWithZeroSpendReadsNothingSpentYet() {
        let text = BudgetBreakdownRowText.statusText(status: .under, limit: 300_000, spent: 0)
        #expect(text == "NOTHING SPENT YET")
    }

    // MARK: - Status Text: Under, Some Spend

    @Test func statusTextUnderWithSomeSpendReadsPercentUsedAndAmountLeft() {
        let text = BudgetBreakdownRowText.statusText(status: .under, limit: 500_000, spent: 310_000)
        #expect(text == "62% USED · Rp190.000 LEFT")
    }

    @Test func statusTextUnderRoundsToTheNearestPercent() {
        let text = BudgetBreakdownRowText.statusText(status: .under, limit: 300_000, spent: 100_000)
        #expect(text == "33% USED · Rp200.000 LEFT")
    }

    // MARK: - Limit Text

    @Test func limitTextReadsLimitPrefixedAmount() {
        #expect(BudgetBreakdownRowText.limitText(limit: 500_000) == "LIMIT Rp500.000")
    }
}
