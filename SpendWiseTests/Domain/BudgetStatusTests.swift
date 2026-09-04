//
//  BudgetStatusTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
@testable import SpendWise

struct BudgetStatusTests {

    // MARK: - noLimit

    @Test func nilLimitIsNoLimitRegardlessOfSpend() {
        #expect(BudgetStatus.evaluate(limit: nil, spent: 0) == .noLimit)
        #expect(BudgetStatus.evaluate(limit: nil, spent: 500_000) == .noLimit)
    }

    // MARK: - under

    @Test func spentBelowLimitIsUnder() {
        #expect(BudgetStatus.evaluate(limit: 100_000, spent: 50_000) == .under)
    }

    @Test func zeroLimitWithZeroSpendIsUnderNotAtLimit() {
        #expect(BudgetStatus.evaluate(limit: 0, spent: 0) == .under)
    }

    // MARK: - atLimit

    @Test func spentEqualToNonzeroLimitIsAtLimit() {
        #expect(BudgetStatus.evaluate(limit: 100_000, spent: 100_000) == .atLimit)
    }

    // MARK: - over

    @Test func spentOneUnitAboveLimitIsOver() {
        #expect(BudgetStatus.evaluate(limit: 100_000, spent: 100_001) == .over)
    }

    @Test func spentWellAboveLimitIsOver() {
        #expect(BudgetStatus.evaluate(limit: 100_000, spent: 250_000) == .over)
    }
}
