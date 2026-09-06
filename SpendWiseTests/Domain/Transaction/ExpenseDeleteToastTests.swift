//
//  ExpenseDeleteToastTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `ExpenseDeleteToast.make(outcome:)`: the pure mapping from an
/// expense-delete outcome to the toast's copy, action label, and visual
/// variant (#14).
struct ExpenseDeleteToastTests {

    @Test func successProducesTheUndoVariant() {
        let toast = ExpenseDeleteToast.make(outcome: .success)

        #expect(toast.variant == .undo)
        #expect(toast.message == "Expense deleted.")
        #expect(toast.actionLabel == "Undo")
    }

    @Test func failureProducesTheErrorVariant() {
        let toast = ExpenseDeleteToast.make(outcome: .failure)

        #expect(toast.variant == .error)
        #expect(toast.message == "Couldn't delete that expense. It's still here — try again.")
        #expect(toast.actionLabel == "Retry")
    }
}
