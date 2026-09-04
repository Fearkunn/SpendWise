//
//  DateLabelFormatterTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `DateLabelFormatter.monthAbbreviation(for:)`, added for the
/// expense sheet's quick-select date chip labels (e.g. "First of Sep",
/// "End of Aug"), which need the month name alone with no year.
struct DateLabelFormatterTests {

    @Test func monthAbbreviationProducesTheThreeLetterMonthNameWithNoYear() throws {
        let date = try date(year: 2026, month: 9, day: 15)
        #expect(DateLabelFormatter.monthAbbreviation(for: date) == "Sep")
    }

    @Test func monthAbbreviationIsStableRegardlessOfDayOfMonth() throws {
        let firstOfMonth = try date(year: 2026, month: 2, day: 1)
        let lastOfMonth = try date(year: 2026, month: 2, day: 28)

        #expect(DateLabelFormatter.monthAbbreviation(for: firstOfMonth) == "Feb")
        #expect(DateLabelFormatter.monthAbbreviation(for: lastOfMonth) == "Feb")
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return try #require(Calendar.current.date(from: components))
    }
}
