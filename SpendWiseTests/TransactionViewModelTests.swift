//
//  TransactionViewModelTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
import SwiftData
import Foundation
@testable import SpendWise

/// Covers `TransactionViewModel`'s CRUD and validation behavior against a
/// fresh in-memory `ModelContext` per test.
///
/// `Transaction.date` is non-optional at the model layer, so "date
/// required" can only be exercised through the ViewModel's own `Date?`
/// parameter — see `addFailsWhenDateIsMissing` below.
@MainActor
struct TransactionViewModelTests {

    // MARK: - Add

    @Test func addPersistsAValidTransaction() throws {
        let (context, viewModel) = makeSUT()

        let transaction = try viewModel.add(amountText: "50000", date: .now, note: "  Coffee  ", category: nil)

        let stored = try context.fetch(FetchDescriptor<Transaction>())
        #expect(stored.count == 1)
        #expect(stored.first === transaction)
        #expect(transaction.amount == 50_000)
        #expect(transaction.note == "Coffee")
        #expect(transaction.category == nil)
    }

    @Test func addStripsNonDigitCharactersFromAmountText() throws {
        let (_, viewModel) = makeSUT()

        let transaction = try viewModel.add(amountText: "Rp 50.000", date: .now, note: "", category: nil)

        #expect(transaction.amount == 50_000)
    }

    @Test func addStoresAnEmptyTrimmedNoteAsEmptyString() throws {
        let (_, viewModel) = makeSUT()

        let transaction = try viewModel.add(amountText: "1000", date: .now, note: "   ", category: nil)

        #expect(transaction.note == "")
    }

    @Test func addAssignsTheGivenCategory() throws {
        let (context, viewModel) = makeSUT()
        let category = Category(name: "Groceries", monthlyLimit: 100_000, colorToken: "green")
        context.insert(category)

        let transaction = try viewModel.add(amountText: "20000", date: .now, note: "", category: category)

        #expect(transaction.category === category)
    }

    @Test func addFailsWhenAmountIsZero() {
        let (_, viewModel) = makeSUT()

        #expect(throws: TransactionValidationError.self) {
            try viewModel.add(amountText: "0", date: .now, note: "", category: nil)
        }
    }

    @Test func addFailsWhenAmountTextHasNoDigits() {
        let (_, viewModel) = makeSUT()

        #expect(throws: TransactionValidationError.self) {
            try viewModel.add(amountText: "abc", date: .now, note: "", category: nil)
        }
    }

    @Test func addFailsWhenDateIsMissing() {
        let (_, viewModel) = makeSUT()

        #expect(throws: TransactionValidationError.self) {
            try viewModel.add(amountText: "10000", date: nil, note: "", category: nil)
        }
    }

    @Test func addDoesNotPersistWhenValidationFails() throws {
        let (context, viewModel) = makeSUT()

        _ = try? viewModel.add(amountText: "0", date: .now, note: "", category: nil)

        let stored = try context.fetch(FetchDescriptor<Transaction>())
        #expect(stored.isEmpty)
    }

    // MARK: - Update

    @Test func updatePersistsChangesToAnExistingTransaction() throws {
        let (context, viewModel) = makeSUT()
        let category = Category(name: "Fun", colorToken: "pink")
        context.insert(category)
        let transaction = try viewModel.add(amountText: "10000", date: .now, note: "Original", category: nil)

        let newDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: .now))
        try viewModel.update(transaction, amountText: "25000", date: newDate, note: "  Updated  ", category: category)

        #expect(transaction.amount == 25_000)
        #expect(transaction.date == newDate)
        #expect(transaction.note == "Updated")
        #expect(transaction.category === category)
    }

    @Test func updateFailsWhenAmountIsNotGreaterThanZero() throws {
        let (_, viewModel) = makeSUT()
        let transaction = try viewModel.add(amountText: "10000", date: .now, note: "", category: nil)

        #expect(throws: TransactionValidationError.self) {
            try viewModel.update(transaction, amountText: "0", date: .now, note: "", category: nil)
        }
    }

    @Test func updateFailsWhenDateIsMissing() throws {
        let (_, viewModel) = makeSUT()
        let transaction = try viewModel.add(amountText: "10000", date: .now, note: "", category: nil)

        #expect(throws: TransactionValidationError.self) {
            try viewModel.update(transaction, amountText: "10000", date: nil, note: "", category: nil)
        }
    }

    // MARK: - Delete

    @Test func deleteRemovesTheTransaction() throws {
        let (context, viewModel) = makeSUT()
        let transaction = try viewModel.add(amountText: "10000", date: .now, note: "", category: nil)

        try viewModel.delete(transaction)

        let stored = try context.fetch(FetchDescriptor<Transaction>())
        #expect(stored.isEmpty)
    }

    // MARK: - SUT Factory

    /// Builds a fresh in-memory `ModelContext` and the `TransactionViewModel`
    /// under test, wired to the same context.
    private func makeSUT() -> (context: ModelContext, viewModel: TransactionViewModel) {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // Force-`try!` is safe here: this is a fixed, hardcoded schema that
        // only runs in tests, so a failure to construct it would mean the
        // schema itself is broken and should fail loudly.
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        return (context, TransactionViewModel(modelContext: context))
    }
}
