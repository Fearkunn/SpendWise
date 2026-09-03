//
//  Transaction.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation
import SwiftData

/// A single expense entry: a whole-number Rupiah amount on a given date,
/// with a free-text note and an optional category.
///
/// Amounts are whole Rupiah — there is no minor unit and no decimal input
/// anywhere in the app's design.
@Model
final class Transaction {

    // MARK: - Properties

    /// The transaction amount in whole Rupiah. There is no decimal
    /// component by design.
    var amount: Int

    /// The date the transaction occurred.
    var date: Date

    /// A free-text note describing the transaction. An empty string is a
    /// valid value — there is no separate "no note" state.
    var note: String

    /// The category this transaction belongs to, if any.
    ///
    /// `nil` means uncategorized, including after the assigned category
    /// has been deleted — see `Category.transactions`'s `.nullify` delete
    /// rule, which is what turns "category deleted" into "transaction
    /// becomes uncategorized" without any ViewModel having to implement it.
    var category: Category?

    // MARK: - Initializers

    init(amount: Int, date: Date = .now, note: String = "", category: Category? = nil) {
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
    }
}
