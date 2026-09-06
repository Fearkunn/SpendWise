//
//  BudgetBreakdownRowText.swift
//  SpendWise
//

import Foundation

/// The per-row copy on the Budget screen's (#18) by-category breakdown: the
/// status line shown alongside each row's bar, and the `LIMIT RpX` caption
/// on the right.
///
/// This is a *different* format from `CategoryBudgetRowText` (the
/// Categories screen's row copy, #15) — same underlying `BudgetStatus`, but
/// this screen spells out the full comparison (`RpX OVER · 108%` vs. the
/// Categories screen's terser `OVER BY RpX`), so it gets its own pure-logic
/// type rather than reusing that one.
enum BudgetBreakdownRowText {

    // MARK: - Status Text

    /// The status line shown beneath a row's bar. Only meaningful when the
    /// category has a limit — callers don't render a bar or this line at
    /// all for a `.noLimit` category (`NO LIMIT SET · TRACKED ONLY` is shown
    /// instead), so `limit` is a plain, non-optional `Int` here rather than
    /// mirroring `BudgetStatus.evaluate(limit:spent:)`'s optional parameter.
    ///
    /// - `.over`: `"Rp<spent - limit> OVER · <percent>%"`.
    /// - `.atLimit`: `"AT LIMIT · 100%"`.
    /// - `.under` with zero spend: `"NOTHING SPENT YET"`.
    /// - `.under` with nonzero spend: `"<percent>% USED · Rp<limit - spent> LEFT"`.
    static func statusText(status: BudgetStatus, limit: Int, spent: Int) -> String {
        switch status {
        case .over:
            let percent = Int((Double(spent) / Double(limit) * 100).rounded())
            return RupiahFormatter.string(from: spent - limit) + " OVER · \(percent)%"
        case .atLimit:
            return "AT LIMIT · 100%"
        case .under:
            guard spent > 0 else { return "NOTHING SPENT YET" }
            let percent = Int((Double(spent) / Double(limit) * 100).rounded())
            return "\(percent)% USED · " + RupiahFormatter.string(from: limit - spent) + " LEFT"
        case .noLimit:
            // Unreachable: this function is only ever called for a row that
            // already has a nonzero limit, so `BudgetStatus.evaluate` (fed a
            // non-nil `limit`) never actually returns `.noLimit` here.
            return ""
        }
    }

    // MARK: - Limit Text

    /// The `LIMIT RpX` caption shown to the right of the status line.
    static func limitText(limit: Int) -> String {
        "LIMIT " + RupiahFormatter.string(from: limit)
    }
}
