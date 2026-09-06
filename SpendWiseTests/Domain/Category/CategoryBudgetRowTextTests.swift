//
//  CategoryBudgetRowTextTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `CategoryBudgetRowText.limitCaption(limit:)` and
/// `.statusLabel(status:limit:spent:)`.
struct CategoryBudgetRowTextTests {

    // MARK: - Limit Caption

    @Test func limitCaptionWithNoLimitReadsNoLimit() {
        #expect(CategoryBudgetRowText.limitCaption(limit: nil) == "no limit")
    }

    @Test func limitCaptionWithALimitReadsOfAmount() {
        #expect(CategoryBudgetRowText.limitCaption(limit: 500_000) == "of Rp500.000")
    }

    // MARK: - Status Label: Over

    @Test func statusLabelOverReadsOverByTheOverage() {
        let label = CategoryBudgetRowText.statusLabel(status: .over, limit: 800_000, spent: 950_000)
        #expect(label == "OVER BY Rp150.000")
    }

    // MARK: - Status Label: At Limit

    @Test func statusLabelAtLimitReadsAtLimit() {
        let label = CategoryBudgetRowText.statusLabel(status: .atLimit, limit: 500_000, spent: 500_000)
        #expect(label == "AT LIMIT")
    }

    // MARK: - Status Label: Under

    @Test func statusLabelUnderWithZeroSpendReadsUntouched() {
        let label = CategoryBudgetRowText.statusLabel(status: .under, limit: 300_000, spent: 0)
        #expect(label == "UNTOUCHED")
    }

    @Test func statusLabelUnderWithSomeSpendReadsRoundedPercentage() {
        let label = CategoryBudgetRowText.statusLabel(status: .under, limit: 400_000, spent: 248_000)
        #expect(label == "62%")
    }

    @Test func statusLabelUnderRoundsToNearestPercent() {
        let label = CategoryBudgetRowText.statusLabel(status: .under, limit: 300_000, spent: 100_000)
        #expect(label == "33%")
    }
}
