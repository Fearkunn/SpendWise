//
//  TransactionListState.swift
//  SpendWise
//

import Foundation

/// The three mutually exclusive states the Transactions screen's list area
/// can be in, per #12.
///
/// Kept as a pure enum with a pure `determine(...)` factory — rather than
/// three `if`/`else` branches inline in the view body — so the
/// state-selection logic itself is unit testable independent of SwiftUI.
enum TransactionListState: Equatable {

    // MARK: - Cases

    /// No transactions exist anywhere, in any month — the first-launch
    /// state.
    case noExpensesAtAll

    /// Transactions exist, but none fall within the currently selected
    /// month. `hasEarlierMonthWithData` distinguishes whether an earlier
    /// month has data to jump back to (affects the empty state's copy and
    /// whether the jump-back pill renders).
    case monthEmpty(hasEarlierMonthWithData: Bool)

    /// The selected month has at least one transaction — the normal
    /// day-grouped list renders.
    case populated

    // MARK: - Determination

    /// Determines which state applies from three already-known facts,
    /// rather than re-deriving them itself — the caller (the view) owns
    /// fetching/filtering via `@Query` and `TransactionMonthLookup`.
    ///
    /// - Parameters:
    ///   - totalTransactionCount: The count of every transaction that
    ///     exists, across all months.
    ///   - monthTransactionCount: The count of transactions within the
    ///     currently selected month only.
    ///   - hasEarlierMonthWithData: Whether
    ///     `TransactionMonthLookup.nearestEarlierMonthWithData(before:in:)`
    ///     found an earlier month with data.
    static func determine(
        totalTransactionCount: Int,
        monthTransactionCount: Int,
        hasEarlierMonthWithData: Bool
    ) -> TransactionListState {
        if totalTransactionCount == 0 {
            return .noExpensesAtAll
        }

        if monthTransactionCount == 0 {
            return .monthEmpty(hasEarlierMonthWithData: hasEarlierMonthWithData)
        }

        return .populated
    }
}
