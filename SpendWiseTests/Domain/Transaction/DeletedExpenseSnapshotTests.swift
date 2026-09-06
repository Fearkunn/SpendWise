//
//  DeletedExpenseSnapshotTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `DeletedExpenseSnapshot.init(transaction:)`: it must capture every
/// field the undo toast (#14) needs to recreate an equivalent transaction,
/// read at initialization time rather than lazily from the (about to be
/// deleted) `Transaction` itself.
struct DeletedExpenseSnapshotTests {

    @Test func capturesEveryFieldFromTheGivenTransaction() {
        let category = SpendWise.Category(name: "Groceries", colorToken: "green")
        let date = Date(timeIntervalSince1970: 1_725_000_000)
        let transaction = Transaction(amount: 45_000, date: date, note: "Snacks", category: category)

        let snapshot = DeletedExpenseSnapshot(transaction: transaction)

        #expect(snapshot.amount == 45_000)
        #expect(snapshot.date == date)
        #expect(snapshot.note == "Snacks")
        #expect(snapshot.category === category)
    }

    @Test func capturesANilCategoryAsNil() {
        let transaction = Transaction(amount: 10_000, date: .now, note: "", category: nil)

        let snapshot = DeletedExpenseSnapshot(transaction: transaction)

        #expect(snapshot.category == nil)
    }
}
