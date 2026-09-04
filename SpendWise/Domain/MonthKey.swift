//
//  MonthKey.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// A calendar month's identity — a specific year and month, independent of
/// any particular day or time within it.
///
/// This exists because "the selected month" (shared across the tab shell)
/// is a calendar-month concept, not an instant in time: paging forward from
/// any day in August should land on September regardless of which day of
/// August the user started from. A raw `Date` doesn't express that
/// identity directly, so `MonthKey` normalizes to year+month and does its
/// own rollover arithmetic rather than relying on `Calendar` date math for
/// every step.
///
/// This is UI state, not entity data — per CLAUDE.md, it does not belong on
/// `TransactionViewModel` or `CategoryViewModel`. It's meant to be held as
/// `@State` on the tab shell and threaded down to tabs as a `Binding`.
struct MonthKey: Hashable, Comparable {

    // MARK: - Properties

    /// The calendar year, e.g. `2026`. Unbounded in both directions — no
    /// clamping is applied when stepping.
    let year: Int

    /// The calendar month, always normalized to `1...12` regardless of what
    /// was passed into the memberwise-style initializer below.
    let month: Int

    // MARK: - Initializers

    /// Creates a month key from a raw year/month pair, normalizing any
    /// out-of-range `month` (e.g. `13`, or `0`) by carrying the overflow
    /// into `year`. This is what makes `advanced(by:)` a simple addition
    /// rather than needing special-cased rollover logic.
    init(year: Int, month: Int) {
        let zeroBasedMonth = month - 1
        let yearOffset = Self.floorDivide(zeroBasedMonth, by: 12)
        let normalizedZeroBasedMonth = zeroBasedMonth - yearOffset * 12

        self.year = year + yearOffset
        self.month = normalizedZeroBasedMonth + 1
    }

    /// Creates a month key from the calendar month `date` falls within.
    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        // `Calendar.dateComponents([.year, .month], from:)` always
        // populates both `year` and `month` for a concrete `Date`, so these
        // defaults are never actually exercised — they only satisfy the
        // optional-to-non-optional conversion.
        self.init(year: components.year ?? 1970, month: components.month ?? 1)
    }

    /// The month `date: .now` falls within.
    static var current: MonthKey {
        MonthKey(date: .now)
    }

    // MARK: - Stepping

    /// This month, offset by `monthOffset` calendar months (negative steps
    /// backward). Unbounded — there is no minimum or maximum `MonthKey`.
    func advanced(by monthOffset: Int) -> MonthKey {
        MonthKey(year: year, month: month + monthOffset)
    }

    /// The next calendar month, rolling over into the next year from
    /// December.
    func next() -> MonthKey {
        advanced(by: 1)
    }

    /// The previous calendar month, rolling back into the previous year
    /// from January.
    func previous() -> MonthKey {
        advanced(by: -1)
    }

    // MARK: - Labels

    /// The full month and year, e.g. `September 2026`.
    var label: String {
        DateLabelFormatter.monthLabel(for: startOfMonth)
    }

    /// The full month and year, uppercased, e.g. `SEPTEMBER 2026`.
    var labelUppercased: String {
        DateLabelFormatter.monthLabelUppercased(for: startOfMonth)
    }

    /// The abbreviated month and year, e.g. `Sep 2026` — used where the
    /// mockup calls for a short label, such as a "back to this month" pill.
    var shortLabel: String {
        DateLabelFormatter.shortMonthLabel(for: startOfMonth)
    }

    /// The abbreviated month name alone, with no year, e.g. `Sep` — used by
    /// the expense sheet's quick-select date chips (e.g. "First of Sep",
    /// "End of Aug"), which never need the year since they're always
    /// relative to the month currently being viewed.
    var monthAbbreviation: String {
        DateLabelFormatter.monthAbbreviation(for: startOfMonth)
    }

    /// A label relative to the current calendar month, e.g. `THIS MONTH`,
    /// `LAST MONTH`, `NEXT MONTH`, or `N MONTHS AGO` / `N MONTHS AHEAD`.
    var relativeLabel: String {
        DateLabelFormatter.relativeMonthLabel(for: startOfMonth)
    }

    // MARK: - Comparable

    static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    // MARK: - Aggregation Bridge

    /// The first moment of this calendar month, per the device's current
    /// calendar.
    ///
    /// Exposed (not `private`) so callers can bridge a `MonthKey` into the
    /// `Date`-based aggregation methods on `TransactionViewModel`
    /// (`monthTotal(in:)` and friends), which only need *some* date inside
    /// the target month — the day is irrelevant to them.
    var startOfMonth: Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        // Safe: `year`/`month` are always normalized by `init(year:month:)`
        // to a valid Gregorian month (1...12), so reconstructing a date
        // from them cannot fail.
        return Calendar.current.date(from: components)!
    }

    /// The last day of this calendar month, at the start of that day, per
    /// the device's current calendar.
    ///
    /// Used by the expense sheet: it's both the default date for a new
    /// expense added while viewing a non-current month (so the new expense
    /// lands inside the month being viewed rather than vanishing from the
    /// filtered list), and the "Last of [month]" quick-select date chip.
    var lastDayOfMonth: Date {
        // Safe: `next().startOfMonth` is always a valid, reconstructible
        // date (see `startOfMonth`'s own safety note), and subtracting one
        // day from the first moment of the next month always lands on a
        // real moment within *this* month, so this cannot fail.
        Calendar.current.date(byAdding: .day, value: -1, to: next().startOfMonth)!
    }

    /// Integer floor division — unlike `/`, this rounds toward negative
    /// infinity rather than toward zero, which is what correct rollover
    /// needs for negative `zeroBasedMonth` values (e.g. paging back from
    /// January).
    private static func floorDivide(_ dividend: Int, by divisor: Int) -> Int {
        let quotient = dividend / divisor
        let remainder = dividend % divisor
        let roundedDownForNegativeRemainder = (remainder != 0) && ((remainder < 0) != (divisor < 0))
        return roundedDownForNegativeRemainder ? quotient - 1 : quotient
    }
}
