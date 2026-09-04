//
//  ExpenseDateChipTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `ExpenseDateChip.quickSelectChips(selectedMonth:today:calendar:)`:
/// which three chips appear (and what they're labeled/dated) depends
/// entirely on whether the *shared selected month* — not any draft date —
/// is the current calendar month.
struct ExpenseDateChipTests {

    // MARK: - Current Month

    @Test func currentMonthShowsTodayYesterdayAndEndOfPreviousMonth() throws {
        let today = try date(year: 2026, month: 9, day: 15)
        let selectedMonth = MonthKey(year: 2026, month: 9)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)

        #expect(chips.map(\.label) == ["Today", "Yesterday", "End of Aug"])
    }

    @Test func currentMonthTodayChipIsStartOfToday() throws {
        let today = try date(year: 2026, month: 9, day: 15, hour: 14)
        let selectedMonth = MonthKey(year: 2026, month: 9)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)
        let todayChip = try #require(chips.first { $0.label == "Today" })

        #expect(Calendar.current.isDate(todayChip.date, inSameDayAs: today))
    }

    @Test func currentMonthYesterdayChipIsOneCalendarDayBack() throws {
        let today = try date(year: 2026, month: 9, day: 1)
        let selectedMonth = MonthKey(year: 2026, month: 9)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)
        let yesterdayChip = try #require(chips.first { $0.label == "Yesterday" })

        let components = Calendar.current.dateComponents([.year, .month, .day], from: yesterdayChip.date)
        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 31)
    }

    @Test func currentMonthEndOfPreviousMonthChipIsThatMonthsLastDay() throws {
        let today = try date(year: 2026, month: 3, day: 10)
        let selectedMonth = MonthKey(year: 2026, month: 3)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)
        let endOfPreviousMonthChip = try #require(chips.first { $0.label == "End of Feb" })

        let components = Calendar.current.dateComponents([.year, .month, .day], from: endOfPreviousMonthChip.date)
        #expect(components.year == 2026)
        #expect(components.month == 2)
        #expect(components.day == 28)
    }

    // MARK: - Other Month

    @Test func otherMonthShowsFirstOfLastOfAndToday() throws {
        let today = try date(year: 2026, month: 9, day: 15)
        let selectedMonth = MonthKey(year: 2026, month: 7)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)

        #expect(chips.map(\.label) == ["First of Jul", "Last of Jul", "Today"])
    }

    @Test func otherMonthFirstAndLastChipsBoundTheSelectedMonth() throws {
        let today = try date(year: 2026, month: 9, day: 15)
        let selectedMonth = MonthKey(year: 2026, month: 7)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)
        let firstChip = try #require(chips.first { $0.label == "First of Jul" })
        let lastChip = try #require(chips.first { $0.label == "Last of Jul" })

        let firstComponents = Calendar.current.dateComponents([.year, .month, .day], from: firstChip.date)
        #expect(firstComponents.year == 2026)
        #expect(firstComponents.month == 7)
        #expect(firstComponents.day == 1)

        let lastComponents = Calendar.current.dateComponents([.year, .month, .day], from: lastChip.date)
        #expect(lastComponents.year == 2026)
        #expect(lastComponents.month == 7)
        #expect(lastComponents.day == 31)
    }

    @Test func otherMonthTodayChipIsStillTodayNotWithinTheSelectedMonth() throws {
        let today = try date(year: 2026, month: 9, day: 15)
        let selectedMonth = MonthKey(year: 2026, month: 7)

        let chips = ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth, today: today)
        let todayChip = try #require(chips.first { $0.label == "Today" })

        #expect(Calendar.current.isDate(todayChip.date, inSameDayAs: today))
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int, hour: Int = 12) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return try #require(Calendar.current.date(from: components))
    }
}
