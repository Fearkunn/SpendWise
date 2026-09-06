//
//  CategoriesSummary.swift
//  SpendWise
//

import Foundation

/// The Categories screen's (#15) header subtitle: a running count of
/// categories plus the sum of every one of their monthly limits.
///
/// Mirrors the source design mockup's `catsSubtitle` derivation exactly,
/// including that it never pluralizes/singularizes the count and that
/// categories with no limit simply contribute `0` to the total rather than
/// being excluded from it.
enum CategoriesSummary {

    // MARK: - Subtitle

    /// - Parameters:
    ///   - count: How many categories currently exist.
    ///   - totalMonthlyLimit: The sum of every existing category's
    ///     `monthlyLimit`, treating `nil` (no limit) as `0`.
    /// - Returns: `"None yet"` when `count` is zero; otherwise
    ///   `"<count> categories · Rp<totalMonthlyLimit> in monthly limits"`.
    static func subtitle(count: Int, totalMonthlyLimit: Int) -> String {
        guard count > 0 else { return "None yet" }
        return "\(count) categories · \(RupiahFormatter.string(from: totalMonthlyLimit)) in monthly limits"
    }
}
