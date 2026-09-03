//
//  PreviewFixturesTests.swift
//  SpendWiseTests
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Testing
import SwiftData
import Foundation
@testable import SpendWise

/// Verifies each preview fixture actually has the shape its doc comments
/// promise. These aren't behavioral tests of app logic — they guard
/// against a future edit to `PreviewFixtures` silently breaking one of the
/// specific states (exactly-at-limit, over-limit, etc.) that later issues
/// rely on being previewable.
struct PreviewFixturesTests {

    // MARK: - Rich

    @Test func richContainsCategoryExactlyAtItsLimit() throws {
        let context = ModelContext(PreviewFixtures.richContainer())
        let groceries = try category(named: "Groceries", in: context)
        let spent = try currentMonthSpend(for: groceries, in: context)

        #expect(groceries.monthlyLimit == spent)
    }

    @Test func richContainsCategoryOverItsLimit() throws {
        let context = ModelContext(PreviewFixtures.richContainer())
        let diningOut = try category(named: "Dining out", in: context)
        let limit = try #require(diningOut.monthlyLimit)
        let spent = try currentMonthSpend(for: diningOut, in: context)

        #expect(spent > limit)
    }

    @Test func richContainsFundedCategoryWithZeroSpend() throws {
        let context = ModelContext(PreviewFixtures.richContainer())
        let home = try category(named: "Home", in: context)

        #expect(home.monthlyLimit != nil)
        #expect(home.transactions.isEmpty)
    }

    @Test func richContainsUncategorizedSpend() throws {
        let context = ModelContext(PreviewFixtures.richContainer())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())

        #expect(transactions.contains { $0.category == nil })
    }

    @Test func richContainsAFutureDatedExpense() throws {
        let context = ModelContext(PreviewFixtures.richContainer())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())

        #expect(transactions.contains { $0.date > Date() })
    }

    @Test func richHasACategoryWithNoLimit() throws {
        let context = ModelContext(PreviewFixtures.richContainer())
        let fun = try category(named: "Fun", in: context)

        #expect(fun.monthlyLimit == nil)
    }

    // MARK: - Sparse

    @Test func sparseTransactionsAllFallWithinTheLastWeek() throws {
        let context = ModelContext(PreviewFixtures.sparseContainer())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let aWeekAgo = try #require(Calendar.current.date(byAdding: .day, value: -7, to: Date()))

        #expect(!transactions.isEmpty)
        #expect(transactions.allSatisfy { $0.date >= aWeekAgo })
    }

    // MARK: - First Launch

    @Test func firstLaunchHasCategoriesButNoTransactions() throws {
        let context = ModelContext(PreviewFixtures.firstLaunchContainer())
        let categories = try context.fetch(FetchDescriptor<SpendWise.Category>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())

        #expect(!categories.isEmpty)
        #expect(transactions.isEmpty)
    }

    // MARK: - No Categories

    @Test func noCategoriesHasTransactionsButNoCategories() throws {
        let context = ModelContext(PreviewFixtures.noCategoriesContainer())
        let categories = try context.fetch(FetchDescriptor<SpendWise.Category>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())

        #expect(categories.isEmpty)
        #expect(!transactions.isEmpty)
        #expect(transactions.allSatisfy { $0.category == nil })
    }

    // MARK: - Helpers

    private func category(named name: String, in context: ModelContext) throws -> SpendWise.Category {
        var descriptor = FetchDescriptor<SpendWise.Category>(predicate: #Predicate { $0.name == name })
        descriptor.fetchLimit = 1
        return try #require(try context.fetch(descriptor).first)
    }

    private func currentMonthSpend(for category: SpendWise.Category, in context: ModelContext) throws -> Int {
        category.transactions
            .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}
