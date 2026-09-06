//
//  CategoryDeleteConfirmationCopy.swift
//  SpendWise
//

import Foundation

/// The title and body copy for the category delete confirmation dialog
/// (#17), plus its two action labels.
///
/// Pulled out as pure functions, matching this codebase's established
/// precedent (`CategoryBudgetRowText`, `CategoryLimitHint`), so the
/// zero/singular/plural boundary logic in `body(expenseCount:)` is unit
/// testable independently of `CategoryDeleteConfirmationView`'s SwiftUI
/// body.
enum CategoryDeleteConfirmationCopy {

    // MARK: - Title

    /// - Parameter categoryName: The name of the category being deleted.
    static func title(categoryName: String) -> String {
        "Delete \"\(categoryName)\"?"
    }

    // MARK: - Body

    /// - Parameter expenseCount: The all-time number of expenses currently
    ///   assigned to the category being deleted — see
    ///   `TransactionViewModel.count(categoryID:)`.
    /// - Returns: A reassurance that nothing else changes when `expenseCount`
    ///   is `0`; otherwise a singular/plural-correct description of how many
    ///   expenses become Uncategorized.
    static func body(expenseCount: Int) -> String {
        guard expenseCount > 0 else {
            return "No expenses use this category, so nothing else changes. The limit is removed from your total budget."
        }

        let subject = expenseCount == 1 ? "expense becomes" : "expenses become"
        return "\(expenseCount) \(subject) Uncategorized. They stay in your list and month totals, but drop out of the category breakdown."
    }

    // MARK: - Actions

    static let keepActionTitle = "Keep it"
    static let deleteActionTitle = "Delete category"
}
