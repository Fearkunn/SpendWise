//
//  BudgetStatus.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// How a category's spending compares to its monthly budget limit.
///
/// This is the reference implementation of the cross-entity ownership rule
/// in CLAUDE.md: `evaluate(limit:spent:)` is a pure function that takes the
/// amount spent as a parameter rather than computing it itself, so this type
/// has no dependency on `Transaction` or any ViewModel. `CategoryViewModel`
/// (added separately) exposes this as `budgetStatus(limit:spent:)`, with the
/// View responsible for supplying the spent amount from
/// `TransactionViewModel`.
enum BudgetStatus {

    // MARK: - Cases

    /// The category has no monthly limit set.
    case noLimit

    /// Spending is below the limit, or the limit is zero and nothing has
    /// been spent.
    case under

    /// Spending exactly equals a nonzero limit.
    case atLimit

    /// Spending is strictly greater than the limit.
    case over

    // MARK: - Methods

    /// Determines budget status from a category's `limit` and the amount
    /// `spent` against it.
    ///
    /// - `limit == nil` is always `.noLimit`, regardless of `spent`.
    /// - `.atLimit` requires exact equality *and* nonzero spend — a zero
    ///   limit with zero spend is `.under`, not `.atLimit`.
    /// - `.over` requires spend strictly greater than the limit; hitting
    ///   the limit exactly is never `.over`.
    static func evaluate(limit: Int?, spent: Int) -> BudgetStatus {
        guard let limit else {
            return .noLimit
        }

        if spent > limit {
            return .over
        }

        if spent == limit && spent > 0 {
            return .atLimit
        }

        return .under
    }
}
