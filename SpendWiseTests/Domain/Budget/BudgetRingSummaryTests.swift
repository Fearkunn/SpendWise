//
//  BudgetRingSummaryTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `BudgetRingSummary.make(spent:totalLimit:)`.
struct BudgetRingSummaryTests {

    // MARK: - No Budget

    @Test func noBudgetReadsAsAnEmDash() {
        let summary = BudgetRingSummary.make(spent: 0, totalLimit: 0)

        #expect(summary.percentText == "—")
        #expect(summary.ringFraction == 0)
    }

    @Test func noBudgetWithSpendStillReadsAsAnEmDashButIsOverBudget() {
        // Per the issue's accepted derivation: with no limits at all,
        // any spend against no-limit categories still reads as
        // "OVER BUDGET BY" that amount, even though the ring itself shows
        // no percentage.
        let summary = BudgetRingSummary.make(spent: 100_000, totalLimit: 0)

        #expect(summary.percentText == "—")
        #expect(summary.ringFraction == 0)
        #expect(summary.isOverBudget)
        #expect(summary.remainLabel == "OVER BUDGET BY")
        #expect(summary.remainText == "Rp100.000")
    }

    // MARK: - Under Budget

    @Test func underBudgetReadsLeftToSpend() {
        let summary = BudgetRingSummary.make(spent: 400_000, totalLimit: 1_000_000)

        #expect(summary.percentText == "40%")
        #expect(summary.ringFraction == 0.4)
        #expect(!summary.isOverBudget)
        #expect(summary.remainLabel == "LEFT TO SPEND")
        #expect(summary.remainText == "Rp600.000")
    }

    // MARK: - Exactly At Limit

    @Test func exactlyAtLimitStillReadsLeftToSpendWithZeroRemaining() {
        let summary = BudgetRingSummary.make(spent: 1_000_000, totalLimit: 1_000_000)

        #expect(summary.percentText == "100%")
        #expect(summary.ringFraction == 1.0)
        #expect(!summary.isOverBudget)
        #expect(summary.remainLabel == "LEFT TO SPEND")
        #expect(summary.remainText == "Rp0")
    }

    // MARK: - Over Budget

    @Test func overBudgetReadsOverBudgetBy() {
        let summary = BudgetRingSummary.make(spent: 1_200_000, totalLimit: 1_000_000)

        #expect(summary.percentText == "120%")
        #expect(summary.ringFraction == 1.0)
        #expect(summary.isOverBudget)
        #expect(summary.remainLabel == "OVER BUDGET BY")
        #expect(summary.remainText == "Rp200.000")
    }

    @Test func ringFractionIsCappedAtOneEvenFarOverBudget() {
        let summary = BudgetRingSummary.make(spent: 5_000_000, totalLimit: 1_000_000)

        #expect(summary.ringFraction == 1.0)
    }

    // MARK: - Rounding

    @Test func percentTextRoundsToTheNearestPercent() {
        let summary = BudgetRingSummary.make(spent: 100_000, totalLimit: 300_000)

        #expect(summary.percentText == "33%")
    }
}
