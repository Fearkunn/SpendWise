//
//  ExpenseMonthImpactNoteTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `ExpenseMonthImpactNote.make(selectedMonth:date:today:calendar:)`:
/// the three copy variants, and the precedence rule that a future-dated
/// expense reads as "dated ahead" even when it falls within the month
/// currently being viewed.
struct ExpenseMonthImpactNoteTests {

    // MARK: - Same Month

    @Test func sameMonthNonFutureDateProducesTheInMonthVariant() throws {
        let selectedMonth = MonthKey(year: 2026, month: 9)
        let date = try makeDate(year: 2026, month: 9, day: 2)
        let today = try makeDate(year: 2026, month: 9, day: 4)

        let note = ExpenseMonthImpactNote.make(selectedMonth: selectedMonth, date: date, today: today)

        #expect(note.variant == .sameMonth)
        #expect(note.text == "Counts toward your September 2026 budget — the month you are viewing.")
        #expect(note.isEmphasized == false)
    }

    @Test func sameMonthIncludesTodayItself() throws {
        let selectedMonth = MonthKey(year: 2026, month: 9)
        let today = try makeDate(year: 2026, month: 9, day: 4)

        let note = ExpenseMonthImpactNote.make(selectedMonth: selectedMonth, date: today, today: today)

        #expect(note.variant == .sameMonth)
    }

    // MARK: - Different Month

    @Test func differentMonthNonFutureDateProducesTheLeavesVariant() throws {
        let selectedMonth = MonthKey(year: 2026, month: 9)
        let date = try makeDate(year: 2026, month: 7, day: 10)
        let today = try makeDate(year: 2026, month: 9, day: 4)

        let note = ExpenseMonthImpactNote.make(selectedMonth: selectedMonth, date: date, today: today)

        #expect(note.variant == .differentMonth)
        #expect(note.text == "Leaves September 2026 — it will count toward July 2026, and the app will jump there on save.")
        #expect(note.isEmphasized == true)
    }

    // MARK: - Future

    @Test func futureDateInAnyMonthProducesTheDatedAheadVariant() throws {
        let selectedMonth = MonthKey(year: 2026, month: 9)
        let date = try makeDate(year: 2026, month: 11, day: 20)
        let today = try makeDate(year: 2026, month: 9, day: 4)

        let note = ExpenseMonthImpactNote.make(selectedMonth: selectedMonth, date: date, today: today)

        #expect(note.variant == .future)
        #expect(note.text == "Dated ahead — counts toward November 2026 once that month arrives.")
        #expect(note.isEmphasized == true)
    }

    @Test func futureDateWithinTheSelectedMonthStillProducesTheDatedAheadVariant() throws {
        // A future-dated day later in the same month being viewed should
        // still read as "dated ahead," not the plain in-month note —
        // `.future` takes precedence over `.sameMonth`.
        let selectedMonth = MonthKey(year: 2026, month: 9)
        let today = try makeDate(year: 2026, month: 9, day: 4)
        let date = try makeDate(year: 2026, month: 9, day: 20)

        let note = ExpenseMonthImpactNote.make(selectedMonth: selectedMonth, date: date, today: today)

        #expect(note.variant == .future)
        #expect(note.isEmphasized == true)
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return try #require(Calendar.current.date(from: components))
    }
}
