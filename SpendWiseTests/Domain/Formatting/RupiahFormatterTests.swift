//
//  RupiahFormatterTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `RupiahFormatter.groupedDigits(from:)`: the expense sheet's
/// live-grouping amount display, kept separate from
/// `TransactionViewModel.add(amountText:...)`'s own digit-only parsing, but
/// deliberately mirroring the same "discard everything but digits" rule so
/// what's displayed always matches what will actually be saved.
struct RupiahFormatterTests {

    @Test func groupsPlainDigitsWithPeriodSeparators() {
        #expect(RupiahFormatter.groupedDigits(from: "1350000") == "1.350.000")
    }

    @Test func discardsNonDigitCharactersBeforeGrouping() {
        #expect(RupiahFormatter.groupedDigits(from: "Rp 50.000") == "50.000")
    }

    @Test func leavesSmallAmountsUngrouped() {
        #expect(RupiahFormatter.groupedDigits(from: "500") == "500")
    }

    @Test func emptyInputProducesAnEmptyString() {
        #expect(RupiahFormatter.groupedDigits(from: "") == "")
    }

    @Test func inputWithNoDigitsAtAllProducesAnEmptyString() {
        #expect(RupiahFormatter.groupedDigits(from: "Rp") == "")
    }

    @Test func leadingZerosAreNotPreservedInTheGroupedResult() {
        #expect(RupiahFormatter.groupedDigits(from: "007000") == "7.000")
    }

    @Test func zeroFormatsAsZeroRatherThanAnEmptyString() {
        #expect(RupiahFormatter.groupedDigits(from: "0") == "0")
    }
}
