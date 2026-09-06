//
//  DeletedExpenseSnapshot.swift
//  SpendWise
//

import Foundation

/// A capture of a `Transaction`'s field values at the moment it's deleted.
///
/// `TransactionViewModel.delete(_:)` removes the object from the model
/// context, so nothing about the deleted record is left to read afterward.
/// The undo toast (#14) needs those values to recreate an equivalent
/// transaction if the user taps Undo, so they're captured into this plain
/// value type *before* the delete call, not after.
struct DeletedExpenseSnapshot {

    // MARK: - Properties

    let amount: Int
    let date: Date
    let note: String
    let category: Category?

    // MARK: - Initializers

    init(transaction: Transaction) {
        amount = transaction.amount
        date = transaction.date
        note = transaction.note
        category = transaction.category
    }
}
