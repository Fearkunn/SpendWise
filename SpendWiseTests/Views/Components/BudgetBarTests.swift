//
//  BudgetBarTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
@testable import SpendWise

/// `BudgetBar` is a SwiftUI view and isn't unit-tested directly (matching
/// this codebase's existing precedent for Views). `cappedFraction(_:)` is
/// the one piece of pure, extractable logic it contains — the fill-width
/// math that caps an over-budget fraction at `1.0` — so it's tested here in
/// isolation.
struct BudgetBarTests {

    @Test func fractionBelowOneIsUnchanged() {
        #expect(BudgetBar.cappedFraction(0.45) == 0.45)
    }

    @Test func fractionExactlyOneIsUnchanged() {
        #expect(BudgetBar.cappedFraction(1.0) == 1.0)
    }

    @Test func fractionAboveOneIsCappedAtOne() {
        #expect(BudgetBar.cappedFraction(1.4) == 1.0)
    }

    @Test func zeroFractionStaysZero() {
        #expect(BudgetBar.cappedFraction(0) == 0)
    }

    @Test func negativeFractionIsClampedToZero() {
        #expect(BudgetBar.cappedFraction(-0.2) == 0)
    }
}
