//
//  CategoryDeleteConfirmationCopyTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `CategoryDeleteConfirmationCopy.title(categoryName:)` and
/// `.body(expenseCount:)`, including the zero/singular/plural boundary
/// cases the confirmation dialog's copy depends on.
struct CategoryDeleteConfirmationCopyTests {

    // MARK: - Title

    @Test func titleWrapsTheCategoryNameInQuotesWithAQuestionMark() {
        let title = CategoryDeleteConfirmationCopy.title(categoryName: "Dining out")
        #expect(title == "Delete \"Dining out\"?")
    }

    // MARK: - Body: Zero Expenses

    @Test func bodyWithZeroExpensesReassuresNothingElseChanges() {
        let body = CategoryDeleteConfirmationCopy.body(expenseCount: 0)
        #expect(body == "No expenses use this category, so nothing else changes. The limit is removed from your total budget.")
    }

    // MARK: - Body: Singular

    @Test func bodyWithOneExpenseUsesSingularWording() {
        let body = CategoryDeleteConfirmationCopy.body(expenseCount: 1)
        #expect(body == "1 expense becomes Uncategorized. They stay in your list and month totals, but drop out of the category breakdown.")
    }

    // MARK: - Body: Plural

    @Test func bodyWithMultipleExpensesUsesPluralWording() {
        let body = CategoryDeleteConfirmationCopy.body(expenseCount: 12)
        #expect(body == "12 expenses become Uncategorized. They stay in your list and month totals, but drop out of the category breakdown.")
    }

    @Test func bodyWithTwoExpensesUsesPluralWording() {
        let body = CategoryDeleteConfirmationCopy.body(expenseCount: 2)
        #expect(body == "2 expenses become Uncategorized. They stay in your list and month totals, but drop out of the category breakdown.")
    }
}
