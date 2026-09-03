//
//  DateLabelFormatter.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// Formats the date-related labels shown across SpendWise: day-group
/// headers, per-row dates, and month labels (both absolute and relative to
/// "now").
///
/// SpendWise's copy is intentionally not localized, so weekday and month
/// names are fixed to a stable English form regardless of the device's
/// locale or calendar — only the underlying "what day/month is this"
/// arithmetic follows the device's actual calendar, via `Calendar.current`.
enum DateLabelFormatter {

    // MARK: - Methods

    /// The header shown above a group of same-day transactions: `TODAY`,
    /// `YESTERDAY`, or otherwise a day-of-week/day/month label such as
    /// `WED 24 AUG`. Dates after `referenceDate`'s day get a `· UPCOMING`
    /// suffix appended.
    ///
    /// - Parameter referenceDate: The date "today" is measured against.
    ///   Defaults to now; overridable for testing.
    static func dayHeader(for date: Date, referenceDate: Date = .now) -> String {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let startOfReference = calendar.startOfDay(for: referenceDate)
        let daysFromReference = calendar.dateComponents(
            [.day],
            from: startOfReference,
            to: startOfDate
        ).day ?? 0

        switch daysFromReference {
        case 0:
            return "TODAY"
        case -1:
            return "YESTERDAY"
        default:
            let base = dayMonthFormatter.string(from: date).uppercased()
            return daysFromReference > 0 ? "\(base) · UPCOMING" : base
        }
    }

    /// The date shown on an individual transaction row, e.g. `Thu 2 Sep`.
    static func rowDate(for date: Date) -> String {
        dayMonthFormatter.string(from: date)
    }

    /// The full month and year, e.g. `September 2026`.
    static func monthLabel(for date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    /// The full month and year, uppercased, e.g. `SEPTEMBER 2026`.
    static func monthLabelUppercased(for date: Date) -> String {
        monthLabel(for: date).uppercased()
    }

    /// The abbreviated month and year, e.g. `Sep 2026`.
    static func shortMonthLabel(for date: Date) -> String {
        shortMonthYearFormatter.string(from: date)
    }

    /// A month label relative to `referenceDate`'s month: `THIS MONTH`,
    /// `LAST MONTH`, `NEXT MONTH`, or `N MONTHS AGO` / `N MONTHS AHEAD`
    /// for anything further away.
    ///
    /// - Parameter referenceDate: The month "this month" is measured
    ///   against. Defaults to now; overridable for testing.
    static func relativeMonthLabel(for date: Date, referenceDate: Date = .now) -> String {
        let calendar = Calendar.current
        let referenceComponents = calendar.dateComponents([.year, .month], from: referenceDate)
        let targetComponents = calendar.dateComponents([.year, .month], from: date)

        // Reconstructing a date from the year/month components just
        // extracted from two real `Date` values cannot fail — there is no
        // invalid year/month pairing to produce here — so force-unwrapping
        // the `Date?` `Calendar.date(from:)` returns is safe.
        let referenceMonthStart = calendar.date(from: referenceComponents)!
        let targetMonthStart = calendar.date(from: targetComponents)!

        let monthsFromReference = calendar.dateComponents(
            [.month],
            from: referenceMonthStart,
            to: targetMonthStart
        ).month ?? 0

        switch monthsFromReference {
        case 0:
            return "THIS MONTH"
        case -1:
            return "LAST MONTH"
        case 1:
            return "NEXT MONTH"
        case ..<(-1):
            return "\(abs(monthsFromReference)) MONTHS AGO"
        default:
            return "\(monthsFromReference) MONTHS AHEAD"
        }
    }

    // MARK: - Private

    /// Fixed so weekday/month names render in stable, non-localized
    /// English (e.g. `WED`, `AUG`) regardless of the device's locale or
    /// calendar system.
    private static let locale = Locale(identifier: "en_US_POSIX")
    private static let calendar = Calendar(identifier: .gregorian)

    /// Produces e.g. `Wed 24 Aug` / `Thu 2 Sep`; callers uppercase this
    /// where the design calls for it.
    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "EEE d MMM"
        return formatter
    }()

    /// Produces e.g. `September 2026`.
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Produces e.g. `Sep 2026`.
    private static let shortMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}
