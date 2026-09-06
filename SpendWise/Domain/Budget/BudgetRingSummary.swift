//
//  BudgetRingSummary.swift
//  SpendWise
//

import Foundation

/// The Budget screen's (#18) summary-card figures derived from the month's
/// categorized spend and the sum of every current category's monthly limit:
/// the donut ring's fill fraction and center percentage, and the
/// "LEFT TO SPEND" / "OVER BUDGET BY" line beneath it.
///
/// Mirrors the source design mockup's derivation exactly. `totalLimit` is
/// the sum of every *current* category's `monthlyLimit` (`nil` treated as
/// `0`) — per the issue's accepted behavior, limits aren't versioned per
/// month, so a past month's ring still compares against today's limits.
/// `spent` is the sum of that month's spend attributed to a still-existing
/// category (`TransactionViewModel.spent(in:categoryID:)` summed across
/// every current `Category`) — excluding uncategorized spend, which the
/// ring and this figure deliberately don't include.
///
/// A pure, testable value type — no dependency on `Transaction`,
/// `Category`, or either ViewModel, matching `CategoryBudgetRowText`'s
/// precedent for this screen's other pure-logic piece.
struct BudgetRingSummary: Equatable {

    // MARK: - Properties

    /// The center-of-ring percentage text, e.g. `"62%"`, or `"—"` when
    /// `totalLimit` is `0` (no budget exists to measure against).
    let percentText: String

    /// The ring's fill fraction, already clamped to `0...1` — `0` when
    /// `totalLimit` is `0`. Safe to feed directly into a ring/arc view with
    /// no further capping needed.
    let ringFraction: Double

    /// `"OVER BUDGET BY"` or `"LEFT TO SPEND"`, switching exactly when
    /// `spent` exceeds `totalLimit` (equal is still "left to spend", not
    /// "over").
    let remainLabel: String

    /// The absolute difference between `spent` and `totalLimit`, formatted
    /// as Rupiah — always reads as a positive amount regardless of which
    /// direction `remainLabel` indicates.
    let remainText: String

    /// Whether `spent` strictly exceeds `totalLimit` — drives `remainLabel`
    /// and is exposed separately so the view can also color the remain
    /// figure without re-deriving this comparison itself.
    let isOverBudget: Bool

    // MARK: - Derivation

    /// - Parameters:
    ///   - spent: The month's spend attributed to a still-existing category.
    ///   - totalLimit: The sum of every current category's `monthlyLimit`,
    ///     treating `nil` as `0`.
    static func make(spent: Int, totalLimit: Int) -> BudgetRingSummary {
        let hasBudget = totalLimit > 0
        let isOverBudget = spent > totalLimit

        let percentText: String
        let ringFraction: Double
        if hasBudget {
            let rawFraction = Double(spent) / Double(totalLimit)
            let percent = Int((rawFraction * 100).rounded())
            percentText = "\(percent)%"
            ringFraction = max(0, min(rawFraction, 1))
        } else {
            percentText = "—"
            ringFraction = 0
        }

        return BudgetRingSummary(
            percentText: percentText,
            ringFraction: ringFraction,
            remainLabel: isOverBudget ? "OVER BUDGET BY" : "LEFT TO SPEND",
            remainText: RupiahFormatter.string(from: abs(totalLimit - spent)),
            isOverBudget: isOverBudget
        )
    }
}
