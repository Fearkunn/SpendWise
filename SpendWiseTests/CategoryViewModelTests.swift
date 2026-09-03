//
//  CategoryViewModelTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
import SwiftData
import Foundation
@testable import SpendWise

/// Covers `CategoryViewModel`'s CRUD and validation behavior against a
/// fresh in-memory `ModelContext` per test.
@MainActor
struct CategoryViewModelTests {

    // MARK: - Add: Name Validation

    @Test func addPersistsAValidCategory() throws {
        let (context, viewModel) = makeSUT()

        let category = try viewModel.add(name: "  Groceries  ", monthlyLimitText: "500000")

        let stored = try context.fetch(FetchDescriptor<SpendWise.Category>())
        #expect(stored.count == 1)
        #expect(stored.first === category)
        #expect(category.name == "Groceries")
        #expect(category.monthlyLimit == 500_000)
    }

    @Test func addFailsWhenNameIsEmpty() {
        let (_, viewModel) = makeSUT()

        #expect(throws: CategoryValidationError.self) {
            try viewModel.add(name: "", monthlyLimitText: "")
        }
    }

    @Test func addFailsWhenNameIsWhitespaceOnly() {
        let (_, viewModel) = makeSUT()

        #expect(throws: CategoryValidationError.self) {
            try viewModel.add(name: "   ", monthlyLimitText: "")
        }
    }

    @Test func addDoesNotPersistWhenValidationFails() throws {
        let (context, viewModel) = makeSUT()

        _ = try? viewModel.add(name: "", monthlyLimitText: "")

        let stored = try context.fetch(FetchDescriptor<SpendWise.Category>())
        #expect(stored.isEmpty)
    }

    @Test func addFailsOnCaseInsensitiveDuplicateName() throws {
        let (_, viewModel) = makeSUT()
        try viewModel.add(name: "Groceries", monthlyLimitText: "")

        #expect(throws: CategoryValidationError.self) {
            try viewModel.add(name: "groceries", monthlyLimitText: "")
        }
    }

    @Test func addSucceedsWithDistinctName() throws {
        let (_, viewModel) = makeSUT()
        try viewModel.add(name: "Groceries", monthlyLimitText: "")

        let second = try viewModel.add(name: "Transport", monthlyLimitText: "")

        #expect(second.name == "Transport")
    }

    // MARK: - Add: Zero-Limit Rule

    @Test func addNormalizesAZeroLimitToNil() throws {
        let (_, viewModel) = makeSUT()

        let category = try viewModel.add(name: "Fun", monthlyLimitText: "0")

        #expect(category.monthlyLimit == nil)
    }

    @Test func addNormalizesEmptyLimitTextToNil() throws {
        let (_, viewModel) = makeSUT()

        let category = try viewModel.add(name: "Fun", monthlyLimitText: "")

        #expect(category.monthlyLimit == nil)
    }

    @Test func addStripsNonDigitCharactersFromLimitText() throws {
        let (_, viewModel) = makeSUT()

        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "Rp 500.000")

        #expect(category.monthlyLimit == 500_000)
    }

    // MARK: - Add: Color Assignment

    @Test func addAssignsTheFirstUnusedColor() throws {
        let (_, viewModel) = makeSUT()

        let first = try viewModel.add(name: "Groceries", monthlyLimitText: "")
        let second = try viewModel.add(name: "Transport", monthlyLimitText: "")

        #expect(first.colorToken == CategoryViewModel.colorPalette[0])
        #expect(second.colorToken == CategoryViewModel.colorPalette[1])
    }

    @Test func addSkipsAColorAlreadyUsedByAnExistingCategory() throws {
        let (context, viewModel) = makeSUT()
        // Pre-insert a category directly (bypassing the ViewModel) that
        // already occupies the first palette color.
        let existing = Category(name: "Existing", colorToken: CategoryViewModel.colorPalette[0])
        context.insert(existing)
        try context.save()

        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "")

        #expect(category.colorToken == CategoryViewModel.colorPalette[1])
    }

    @Test func addCyclesByIndexOnceAllColorsAreUsed() throws {
        let (context, viewModel) = makeSUT()
        for token in CategoryViewModel.colorPalette {
            context.insert(Category(name: "Category-\(token)", colorToken: token))
        }
        try context.save()

        let category = try viewModel.add(name: "Overflow", monthlyLimitText: "")

        // 8 existing categories, palette has 8 entries: 8 % 8 == 0.
        #expect(category.colorToken == CategoryViewModel.colorPalette[0])
    }

    // MARK: - Update

    @Test func updatePersistsChangesToAnExistingCategory() throws {
        let (_, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "500000")

        try viewModel.update(category, name: "  Food  ", monthlyLimitText: "600000")

        #expect(category.name == "Food")
        #expect(category.monthlyLimit == 600_000)
    }

    @Test func updateDoesNotChangeTheColorToken() throws {
        let (_, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "")
        let originalToken = category.colorToken

        try viewModel.update(category, name: "Food", monthlyLimitText: "")

        #expect(category.colorToken == originalToken)
    }

    @Test func updateFailsWhenNameIsEmpty() throws {
        let (_, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "")

        #expect(throws: CategoryValidationError.self) {
            try viewModel.update(category, name: "   ", monthlyLimitText: "")
        }
    }

    @Test func updateFailsWhenNameDuplicatesAnotherCategory() throws {
        let (_, viewModel) = makeSUT()
        try viewModel.add(name: "Groceries", monthlyLimitText: "")
        let transport = try viewModel.add(name: "Transport", monthlyLimitText: "")

        #expect(throws: CategoryValidationError.self) {
            try viewModel.update(transport, name: "groceries", monthlyLimitText: "")
        }
    }

    @Test func updateSucceedsWhenRenamingToItsOwnCurrentNameWithDifferentCase() throws {
        let (_, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "")

        try viewModel.update(category, name: "groceries", monthlyLimitText: "")

        #expect(category.name == "groceries")
    }

    @Test func updateNormalizesAZeroLimitToNil() throws {
        let (_, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "500000")

        try viewModel.update(category, name: "Groceries", monthlyLimitText: "0")

        #expect(category.monthlyLimit == nil)
    }

    // MARK: - Delete

    @Test func deleteRemovesTheCategory() throws {
        let (context, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "")

        try viewModel.delete(category)

        let stored = try context.fetch(FetchDescriptor<SpendWise.Category>())
        #expect(stored.isEmpty)
    }

    @Test func deleteNullifiesTheCategoryOnItsTransactionsWithoutTouchingThem() throws {
        let (context, viewModel) = makeSUT()
        let category = try viewModel.add(name: "Groceries", monthlyLimitText: "")
        let transaction = Transaction(amount: 50_000, note: "Snacks", category: category)
        context.insert(transaction)
        try context.save()

        try viewModel.delete(category)

        let stored = try context.fetch(FetchDescriptor<Transaction>())
        #expect(stored.count == 1)
        #expect(stored.first?.category == nil)
    }

    // MARK: - Budget Status

    @Test func budgetStatusForwardsToBudgetStatusEvaluate() {
        let (_, viewModel) = makeSUT()

        #expect(viewModel.budgetStatus(limit: nil, spent: 100_000) == .noLimit)
        #expect(viewModel.budgetStatus(limit: 100_000, spent: 100_000) == .atLimit)
        #expect(viewModel.budgetStatus(limit: 100_000, spent: 150_000) == .over)
        #expect(viewModel.budgetStatus(limit: 100_000, spent: 50_000) == .under)
    }

    // MARK: - SUT Factory

    /// Builds a fresh in-memory `ModelContext` and the `CategoryViewModel`
    /// under test, wired to the same context.
    private func makeSUT() -> (context: ModelContext, viewModel: CategoryViewModel) {
        let schema = Schema([Transaction.self, SpendWise.Category.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // Force-`try!` is safe here: this is a fixed, hardcoded schema that
        // only runs in tests, so a failure to construct it would mean the
        // schema itself is broken and should fail loudly.
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        return (context, CategoryViewModel(modelContext: context))
    }
}
