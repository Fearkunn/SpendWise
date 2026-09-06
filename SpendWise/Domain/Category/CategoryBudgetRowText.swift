//
//  CategoryBudgetRowText.swift
//  SpendWise
//

import Foundation

/// The two pieces of per-row copy on the Categories screen (#15) that
/// depend on a category's monthly limit and the amount spent against it:
/// the small caption under the spent amount (`of RpX` / `no limit`), and
/// the short status label shown alongside the progress bar (`OVER BY RpX`
/// / `AT LIMIT` / `UNTOUCHED` / `62%`).
///
/// Both mirror the source design mockup's `catRows` derivation exactly
/// (`limitText` and `statusText`), pulled out here as pure functions so
/// they're unit testable independently of `CategoryRow`'s SwiftUI body —
/// matching this codebase's established precedent (`ExpenseNoteHint`,
/// `ExpenseMonthImpactNote`).
enum CategoryBudgetRowText {

    // MARK: - Limit Caption

    /// The small caption shown beneath a row's spent amount.
    ///
    /// - Returns: `"no limit"` when the category has none; otherwise
    ///   `"of Rp<limit>"`.
    static func limitCaption(limit: Int?) -> String {
        guard let limit else { return "no limit" }
        return "of " + RupiahFormatter.string(from: limit)
    }

    // MARK: - Status Label

    /// The short status label shown next to a row's progress bar. Only
    /// meaningful when the category has a limit — callers don't render a
    /// bar or this label at all for a `.noLimit` category, so `limit` is a
    /// plain, non-optional `Int` here rather than mirroring
    /// `BudgetStatus.evaluate(limit:spent:)`'s optional parameter.
    ///
    /// - `.over`: `"OVER BY Rp<spent - limit>"`.
    /// - `.atLimit`: `"AT LIMIT"`.
    /// - `.under` with zero spend: `"UNTOUCHED"` — a funded category
    ///   nothing has been spent against yet.
    /// - `.under` with nonzero spend: the rounded percentage of the limit
    ///   spent so far, e.g. `"62%"`.
    static func statusLabel(status: BudgetStatus, limit: Int, spent: Int) -> String {
        switch status {
        case .over:
            return "OVER BY " + RupiahFormatter.string(from: spent - limit)
        case .atLimit:
            return "AT LIMIT"
        case .under:
            guard spent > 0 else { return "UNTOUCHED" }
            let percent = Int((Double(spent) / Double(limit) * 100).rounded())
            return "\(percent)%"
        case .noLimit:
            // Unreachable: this function is only ever called for a row that
            // already has a nonzero limit, so `BudgetStatus.evaluate` (fed a
            // non-nil `limit`) never actually returns `.noLimit` here.
            return ""
        }
    }
}
