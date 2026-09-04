//
//  MonthKeyTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
import Foundation
@testable import SpendWise

struct MonthKeyTests {

    // MARK: - Construction

    @Test func dateInitializerExtractsYearAndMonth() {
        let date = Self.date(year: 2026, month: 9, day: 15)
        let key = MonthKey(date: date)

        #expect(key.year == 2026)
        #expect(key.month == 9)
    }

    @Test func dateInitializerIgnoresDayOfMonth() {
        let firstOfMonth = MonthKey(date: Self.date(year: 2026, month: 9, day: 1))
        let lastOfMonth = MonthKey(date: Self.date(year: 2026, month: 9, day: 30))

        #expect(firstOfMonth == lastOfMonth)
    }

    // MARK: - Normalization

    @Test func outOfRangeMonthNormalizesForward() {
        // Month 13 should carry over into the next year, same as
        // `advanced(by: 1)` from December.
        let key = MonthKey(year: 2026, month: 13)

        #expect(key.year == 2027)
        #expect(key.month == 1)
    }

    @Test func outOfRangeMonthNormalizesBackward() {
        // Month 0 should roll back into the previous year's December.
        let key = MonthKey(year: 2026, month: 0)

        #expect(key.year == 2025)
        #expect(key.month == 12)
    }

    @Test func farOutOfRangeMonthNormalizesAcrossMultipleYears() {
        // 25 months past January 2026 is February 2028.
        let key = MonthKey(year: 2026, month: 1 + 25)

        #expect(key.year == 2028)
        #expect(key.month == 2)
    }

    // MARK: - Stepping: next()

    @Test func nextStepsForwardWithinAYear() {
        let key = MonthKey(year: 2026, month: 3)
        #expect(key.next() == MonthKey(year: 2026, month: 4))
    }

    @Test func nextRollsOverFromDecemberToNextJanuary() {
        let december = MonthKey(year: 2026, month: 12)
        let next = december.next()

        #expect(next.year == 2027)
        #expect(next.month == 1)
    }

    // MARK: - Stepping: previous()

    @Test func previousStepsBackwardWithinAYear() {
        let key = MonthKey(year: 2026, month: 3)
        #expect(key.previous() == MonthKey(year: 2026, month: 2))
    }

    @Test func previousRollsBackFromJanuaryToPreviousDecember() {
        let january = MonthKey(year: 2026, month: 1)
        let previous = january.previous()

        #expect(previous.year == 2025)
        #expect(previous.month == 12)
    }

    @Test func previousThenNextReturnsToTheOriginalMonth() {
        let key = MonthKey(year: 2026, month: 1)
        #expect(key.previous().next() == key)
    }

    // MARK: - Unbounded range

    @Test func steppingIsUnboundedIntoThePast() {
        var key = MonthKey.current
        for _ in 0..<240 { // 20 years back
            key = key.previous()
        }
        // Should not clamp, crash, or wrap — just keep going.
        #expect(key.year == MonthKey.current.year - 20)
    }

    @Test func steppingIsUnboundedIntoTheFuture() {
        var key = MonthKey.current
        for _ in 0..<240 { // 20 years ahead
            key = key.next()
        }
        #expect(key.year == MonthKey.current.year + 20)
    }

    // MARK: - Comparable

    @Test func comparesByYearThenMonth() {
        #expect(MonthKey(year: 2025, month: 12) < MonthKey(year: 2026, month: 1))
        #expect(MonthKey(year: 2026, month: 1) < MonthKey(year: 2026, month: 2))
        #expect(!(MonthKey(year: 2026, month: 2) < MonthKey(year: 2026, month: 2)))
    }

    // MARK: - Labels

    @Test func labelFormatsFullMonthAndYear() {
        let key = MonthKey(year: 2026, month: 9)
        #expect(key.label == "September 2026")
    }

    @Test func labelUppercasedFormatsFullMonthAndYearUppercased() {
        let key = MonthKey(year: 2026, month: 9)
        #expect(key.labelUppercased == "SEPTEMBER 2026")
    }

    @Test func shortLabelFormatsAbbreviatedMonthAndYear() {
        let key = MonthKey(year: 2026, month: 9)
        #expect(key.shortLabel == "Sep 2026")
    }

    @Test func relativeLabelIsThisMonthForCurrentMonth() {
        #expect(MonthKey.current.relativeLabel == "THIS MONTH")
    }

    @Test func relativeLabelIsLastMonthForOneMonthBack() {
        #expect(MonthKey.current.previous().relativeLabel == "LAST MONTH")
    }

    @Test func relativeLabelIsNextMonthForOneMonthAhead() {
        #expect(MonthKey.current.next().relativeLabel == "NEXT MONTH")
    }

    @Test func relativeLabelCountsMonthsAgoBeyondOneMonthBack() {
        let threeMonthsAgo = MonthKey.current.previous().previous().previous()
        #expect(threeMonthsAgo.relativeLabel == "3 MONTHS AGO")
    }

    @Test func relativeLabelCountsMonthsAheadBeyondOneMonthAhead() {
        let twoMonthsAhead = MonthKey.current.next().next()
        #expect(twoMonthsAhead.relativeLabel == "2 MONTHS AHEAD")
    }

    // MARK: - Aggregation Bridge

    @Test func startOfMonthIsTheFirstDayOfTheMonthAtMidnight() {
        let key = MonthKey(year: 2026, month: 9)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: key.startOfMonth)

        #expect(components.year == 2026)
        #expect(components.month == 9)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    // MARK: - Helpers

    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // Safe: these are fixed, valid calendar components in every test
        // case above (real years/months/days), so reconstruction cannot
        // fail.
        return Calendar.current.date(from: components)!
    }
}
