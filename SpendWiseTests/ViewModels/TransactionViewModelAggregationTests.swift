//
//  TransactionViewModelAggregationTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
import SwiftData
import Foundation
@testable import SpendWise

/// Covers `TransactionViewModel`'s month-scoped aggregation:
/// `monthTotal(in:)`, `spent(in:categoryID:)`, and
/// `uncategorizedTotal(in:)`.
@MainActor
struct TransactionViewModelAggregationTests {

    // MARK: - monthTotal(in:)

    @Test func monthTotalSumsEveryExpenseInTheMonthAcrossCategories() throws {
        let (context, viewModel) = makeSUT()
        let groceries = Category(name: "Groceries", colorToken: "green")
        let transport = Category(name: "Transport", colorToken: "blue")
        context.insert(groceries)
        context.insert(transport)

        let reference = try date(year: 2026, month: 9, day: 15)
        insertTransaction(100_000, on: try date(year: 2026, month: 9, day: 1), category: groceries, in: context)
        insertTransaction(50_000, on: try date(year: 2026, month: 9, day: 20), category: transport, in: context)
        insertTransaction(25_000, on: try date(year: 2026, month: 9, day: 28), category: nil, in: context)

        let total = try viewModel.monthTotal(in: reference)

        #expect(total == 175_000)
    }

    @Test func monthTotalExcludesTransactionsFromOtherMonths() throws {
        let (context, viewModel) = makeSUT()
        let reference = try date(year: 2026, month: 9, day: 15)

        insertTransaction(100_000, on: try date(year: 2026, month: 9, day: 10), category: nil, in: context)
        insertTransaction(999_000, on: try date(year: 2026, month: 8, day: 31), category: nil, in: context)
        insertTransaction(999_000, on: try date(year: 2026, month: 10, day: 1), category: nil, in: context)

        let total = try viewModel.monthTotal(in: reference)

        #expect(total == 100_000)
    }

    // MARK: - Month boundary correctness

    @Test func monthTotalExcludesATransactionAtTheExactStartOfTheNextMonth() throws {
        let (context, viewModel) = makeSUT()
        let reference = try date(year: 2026, month: 9, day: 15)
        let startOfNextMonth = try #require(
            Calendar.current.dateInterval(of: .month, for: reference)?.end
        )

        insertTransaction(500_000, on: startOfNextMonth, category: nil, in: context)
        insertTransaction(50_000, on: try date(year: 2026, month: 9, day: 30), category: nil, in: context)

        let total = try viewModel.monthTotal(in: reference)

        #expect(total == 50_000)
    }

    @Test func monthTotalIncludesATransactionAtTheExactStartOfTheMonth() throws {
        let (context, viewModel) = makeSUT()
        let reference = try date(year: 2026, month: 9, day: 15)
        let startOfMonth = try #require(
            Calendar.current.dateInterval(of: .month, for: reference)?.start
        )

        insertTransaction(50_000, on: startOfMonth, category: nil, in: context)

        let total = try viewModel.monthTotal(in: reference)

        #expect(total == 50_000)
    }

    // MARK: - spent(in:categoryID:)

    @Test func spentSumsOnlyTheGivenCategorysTransactionsInTheMonth() throws {
        let (context, viewModel) = makeSUT()
        let groceries = Category(name: "Groceries", colorToken: "green")
        let transport = Category(name: "Transport", colorToken: "blue")
        context.insert(groceries)
        context.insert(transport)

        let reference = try date(year: 2026, month: 9, day: 15)
        insertTransaction(100_000, on: try date(year: 2026, month: 9, day: 1), category: groceries, in: context)
        insertTransaction(200_000, on: try date(year: 2026, month: 9, day: 5), category: groceries, in: context)
        insertTransaction(50_000, on: try date(year: 2026, month: 9, day: 10), category: transport, in: context)
        // Different month, same category — must not be counted.
        insertTransaction(999_000, on: try date(year: 2026, month: 8, day: 1), category: groceries, in: context)

        let spent = try viewModel.spent(in: reference, categoryID: groceries.persistentModelID)

        #expect(spent == 300_000)
    }

    @Test func spentIsZeroWhenTheCategoryHasNoTransactionsInTheMonth() throws {
        let (context, viewModel) = makeSUT()
        let groceries = Category(name: "Groceries", colorToken: "green")
        context.insert(groceries)

        let reference = try date(year: 2026, month: 9, day: 15)

        let spent = try viewModel.spent(in: reference, categoryID: groceries.persistentModelID)

        #expect(spent == 0)
    }

    // MARK: - uncategorizedTotal(in:) — subtraction-based derivation

    /// Checks the reconciliation invariant `uncategorizedTotal` is expected
    /// to uphold: uncategorized spend plus every live category's spend must
    /// always equal the month total, with no gap or double-count.
    ///
    /// Sets up a scenario where a `Category` is deleted after its
    /// transactions were logged. SwiftData's `.nullify` delete rule turns
    /// each affected transaction's `category` into `nil`, so under today's
    /// schema a filter-based (`category == nil`) implementation would
    /// satisfy this same assertion too — this test doesn't distinguish
    /// between the two. It exists to catch a regression in the invariant
    /// itself, not to prove the subtraction-based derivation is uniquely
    /// correct; that derivation is chosen for reasons that only matter if
    /// the schema changes (see the doc comment on `uncategorizedTotal(in:)`).
    @Test func uncategorizedTotalReconcilesWithMonthTotalAndLiveCategorySpend() throws {
        let (context, viewModel) = makeSUT()
        let groceries = Category(name: "Groceries", colorToken: "green")
        let transport = Category(name: "Transport", colorToken: "blue")
        let deletedLater = Category(name: "Subscriptions", colorToken: "purple")
        context.insert(groceries)
        context.insert(transport)
        context.insert(deletedLater)

        let reference = try date(year: 2026, month: 9, day: 15)
        insertTransaction(100_000, on: try date(year: 2026, month: 9, day: 1), category: groceries, in: context)
        insertTransaction(50_000, on: try date(year: 2026, month: 9, day: 5), category: transport, in: context)
        insertTransaction(75_000, on: try date(year: 2026, month: 9, day: 8), category: deletedLater, in: context)
        insertTransaction(25_000, on: try date(year: 2026, month: 9, day: 20), category: nil, in: context)
        try context.save()

        // Delete the category after the fact — `.nullify` sets its
        // transaction's `category` to `nil`, folding it into
        // "uncategorized" going forward.
        context.delete(deletedLater)
        try context.save()

        let monthTotal = try viewModel.monthTotal(in: reference)
        let groceriesSpent = try viewModel.spent(in: reference, categoryID: groceries.persistentModelID)
        let transportSpent = try viewModel.spent(in: reference, categoryID: transport.persistentModelID)
        let uncategorized = try viewModel.uncategorizedTotal(in: reference)

        #expect(monthTotal == 250_000)
        #expect(groceriesSpent == 100_000)
        #expect(transportSpent == 50_000)
        // The formerly-"Subscriptions" spend (75_000) plus the originally
        // uncategorized spend (25_000) both land here.
        #expect(uncategorized == 100_000)

        // The reconciliation invariant `uncategorizedTotal` is expected to
        // uphold: categorized + uncategorized always equals the month total.
        #expect(monthTotal == groceriesSpent + transportSpent + uncategorized)
    }

    @Test func uncategorizedTotalIsZeroWhenEveryTransactionHasALiveCategory() throws {
        let (context, viewModel) = makeSUT()
        let groceries = Category(name: "Groceries", colorToken: "green")
        context.insert(groceries)

        let reference = try date(year: 2026, month: 9, day: 15)
        insertTransaction(100_000, on: try date(year: 2026, month: 9, day: 1), category: groceries, in: context)

        let uncategorized = try viewModel.uncategorizedTotal(in: reference)

        #expect(uncategorized == 0)
    }

    @Test func uncategorizedTotalEqualsMonthTotalWhenNoCategoriesExist() throws {
        let (context, viewModel) = makeSUT()
        let reference = try date(year: 2026, month: 9, day: 15)

        insertTransaction(60_000, on: try date(year: 2026, month: 9, day: 3), category: nil, in: context)
        insertTransaction(40_000, on: try date(year: 2026, month: 9, day: 12), category: nil, in: context)

        let uncategorized = try viewModel.uncategorizedTotal(in: reference)
        let monthTotal = try viewModel.monthTotal(in: reference)

        #expect(uncategorized == monthTotal)
        #expect(uncategorized == 100_000)
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

    // MARK: - Fixture Helpers

    /// Inserts and saves a `Transaction` directly against the context,
    /// bypassing `TransactionViewModel.add` so tests can freely construct
    /// dates/amounts that wouldn't survive the ViewModel's own validation
    /// text-parsing path.
    private func insertTransaction(_ amount: Int, on date: Date, category: SpendWise.Category?, in context: ModelContext) {
        let transaction = Transaction(amount: amount, date: date, note: "", category: category)
        context.insert(transaction)
        // Force-`try!` is safe here: this is fixed, in-memory test fixture
        // data with a known-good schema — a save failure would mean the
        // fixture itself is broken and should fail loudly.
        try! context.save()
    }

    /// Builds a `Date` for the given calendar components, in the current
    /// calendar/time zone, so it lines up with the same `Calendar.current`
    /// the ViewModel uses to compute month boundaries.
    private func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return try #require(Calendar.current.date(from: components))
    }
}
