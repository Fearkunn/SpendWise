//
//  ExpenseDeleteToast.swift
//  SpendWise
//

/// Whether an attempted expense deletion (#14) succeeded or failed — the
/// input to `ExpenseDeleteToast.make(outcome:)`.
enum ExpenseDeleteOutcome: Equatable {
    case success
    case failure
}

/// The undo/retry toast shown after an attempted expense deletion (#14):
/// copy, action label, and visual variant, derived purely from whether the
/// delete succeeded or failed.
///
/// This only models the toast's *content*. Which record to restore on Undo
/// (a `DeletedExpenseSnapshot`), or which transaction to retry deleting, is
/// view-wiring state that lives on `RootView` instead — per CLAUDE.md,
/// transient UI state doesn't belong on a ViewModel, and holding a live
/// `Transaction` reference isn't "pure logic" either.
struct ExpenseDeleteToast: Equatable {

    // MARK: - Variant

    enum Variant: Equatable {
        /// A successful delete: offers "Undo".
        case undo

        /// A failed delete: the transaction is still there; offers "Retry".
        case error
    }

    // MARK: - Properties

    let variant: Variant
    let message: String
    let actionLabel: String

    // MARK: - Derivation

    static func make(outcome: ExpenseDeleteOutcome) -> ExpenseDeleteToast {
        switch outcome {
        case .success:
            ExpenseDeleteToast(variant: .undo, message: "Expense deleted.", actionLabel: "Undo")
        case .failure:
            ExpenseDeleteToast(
                variant: .error,
                message: "Couldn't delete that expense. It's still here — try again.",
                actionLabel: "Retry"
            )
        }
    }
}
