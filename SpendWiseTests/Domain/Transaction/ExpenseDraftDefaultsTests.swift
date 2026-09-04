//
//  ExpenseDraftDefaultsTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `ExpenseDraftDefaults.date(selectedMonth:today:)`: a new expense
/// defaults to today while viewing the current month, and to the last day
/// of the month while viewing any other month, so it never immediately
/// vanishes from the filtered list on save.
struct ExpenseDraftDefaultsTests {

    @Test func defaultsToTodayWhenViewingTheCurrentMonth() throws {
        let today = try date(year: 2026, month: 9, day: 4)
        let selectedMonth = MonthKey(year: 2026, month: 9)

        let defaultDate = ExpenseDraftDefaults.date(selectedMonth: selectedMonth, today: today)

        #expect(Calendar.current.isDate(defaultDate, inSameDayAs: today))
    }

    @Test func defaultsToTheLastDayOfTheSelectedMonthWhenViewingADifferentMonth() throws {
        let today = try date(year: 2026, month: 9, day: 4)
        let selectedMonth = MonthKey(year: 2026, month: 6)

        let defaultDate = ExpenseDraftDefaults.date(selectedMonth: selectedMonth, today: today)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: defaultDate)

        #expect(components.year == 2026)
        #expect(components.month == 6)
        #expect(components.day == 30)
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
