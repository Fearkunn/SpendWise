//
//  ExpenseMonthImpactNote.swift
//  SpendWise
//

import Foundation

/// The hint line shown under the expense sheet's date field, pre-announcing
/// which month's budget the draft's date will actually count toward.
struct ExpenseMonthImpactNote: Equatable {

    // MARK: - Variant

    enum Variant: Equatable {
        /// The draft's date falls within the month currently being viewed.
        case sameMonth

        /// The draft's date falls within a different month than the one
        /// currently being viewed — saving will jump the shared selected
        /// month to follow it.
        case differentMonth

        /// The draft's date is later than today, regardless of which month
        /// it falls in. Takes priority over `.sameMonth`/`.differentMonth`,
        /// matching the mockup: a same-month-but-future date still reads as
        /// "dated ahead," not as a plain "counts toward this month" note.
        case future
    }

    // MARK: - Properties

    let variant: Variant
    let text: String

    /// Whether this note should render with the accented, semibold
    /// treatment (`.differentMonth` and `.future`) rather than the plain,
    /// muted one (`.sameMonth`) — matching the mockup's `moveDotColor` /
    /// `moveTextColor` / `moveWeight`, which all reduce to this same "is
    /// this the plain in-month case" check.
    var isEmphasized: Bool {
        variant != .sameMonth
    }

    // MARK: - Derivation

    /// - Parameters:
    ///   - selectedMonth: The shared month currently being viewed on the
    ///     Transactions screen.
    ///   - date: The draft expense's currently-picked date.
    ///   - today: The date "future" is measured against. Defaults to now;
    ///     overridable for testing.
    ///   - calendar: The calendar used for month/day arithmetic. Defaults
    ///     to the device's current calendar; overridable for testing.
    static func make(selectedMonth: MonthKey, date: Date, today: Date = .now, calendar: Calendar = .current) -> ExpenseMonthImpactNote {
        let dateMonth = MonthKey(date: date, calendar: calendar)
        let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: today)

        if isFuture {
            return ExpenseMonthImpactNote(
                variant: .future,
                text: "Dated ahead — counts toward \(dateMonth.label) once that month arrives."
            )
        }

        if dateMonth == selectedMonth {
            return ExpenseMonthImpactNote(
                variant: .sameMonth,
                text: "Counts toward your \(selectedMonth.label) budget — the month you are viewing."
            )
        }

        return ExpenseMonthImpactNote(
            variant: .differentMonth,
            text: "Leaves \(selectedMonth.label) — it will count toward \(dateMonth.label), and the app will jump there on save."
        )
    }
}
