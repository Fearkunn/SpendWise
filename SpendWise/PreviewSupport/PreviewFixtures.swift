//
//  PreviewFixtures.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation
import SwiftData

/// Preview-only sample data covering the four dataset shapes the app's
/// design was built and verified against: a rich, multi-month dataset; a
/// sparse one-week dataset; a first-launch dataset with categories but no
/// expenses yet; and a dataset with expenses but no categories at all.
///
/// Each scenario builds its own in-memory `ModelContainer`, so a
/// `#Preview` (or a test exercising a specific shape) can attach one with
/// `.modelContainer(_:)` without ever touching the app's real, persisted
/// store.
enum PreviewFixtures {

    // MARK: - Scenarios

    /// Roughly three months of expenses across seven categories.
    ///
    /// Deliberately engineered so every budget-status edge case is
    /// directly previewable within the *current* calendar month:
    /// - "Groceries" spend exactly equals its limit (`.atLimit`).
    /// - "Dining out" spend exceeds its limit (`.over`).
    /// - "Home" has a limit but zero spend (`.under`, with nothing spent).
    /// - Two transactions have no category at all (uncategorized spend).
    /// - One "Transport" transaction is dated in the future.
    static func richContainer() -> ModelContainer {
        let container = makeContainer()
        let context = container.mainContext

        let categories = standardCategories()
        categories.forEach { context.insert($0) }
        let groceries = categories[0]
        let diningOut = categories[1]
        let transport = categories[2]
        let billsAndUtilities = categories[3]
        let health = categories[4]
        let fun = categories[5]
        // `categories[6]` is "Home" — intentionally left with zero
        // transactions so it previews as a funded, zero-spend category.

        let transactions: [Transaction] = [
            // Groceries — current-month spend sums to exactly the limit.
            Transaction(amount: 450_000, date: currentMonthDate(0.1), note: "Weekly groceries", category: groceries),
            Transaction(amount: 500_000, date: currentMonthDate(0.35), note: "Supermarket run", category: groceries),
            Transaction(amount: 350_000, date: currentMonthDate(0.65), note: "Groceries top-up", category: groceries),
            Transaction(amount: 200_000, date: currentMonthDate(0.9), note: "Fruit and vegetables", category: groceries),
            Transaction(amount: 480_000, date: daysAgo(35), note: "Monthly grocery haul", category: groceries),
            Transaction(amount: 510_000, date: daysAgo(62), note: "Supermarket run", category: groceries),
            Transaction(amount: 460_000, date: daysAgo(88), note: "Groceries", category: groceries),

            // Dining out — current-month spend exceeds the limit.
            Transaction(amount: 120_000, date: currentMonthDate(0.15), note: "Dinner with friends", category: diningOut),
            Transaction(amount: 350_000, date: currentMonthDate(0.4), note: "Birthday dinner", category: diningOut),
            Transaction(amount: 200_000, date: currentMonthDate(0.7), note: "Coffee and pastries", category: diningOut),
            Transaction(amount: 210_000, date: currentMonthDate(0.95), note: "Weekend brunch", category: diningOut),
            Transaction(amount: 150_000, date: daysAgo(40), note: "Ramen night", category: diningOut),
            Transaction(amount: 180_000, date: daysAgo(75), note: "Dinner out", category: diningOut),

            // Transport — under its limit, plus one future-dated expense.
            Transaction(amount: 60_000, date: currentMonthDate(0.2), note: "Ride-hailing to work", category: transport),
            Transaction(amount: 45_000, date: currentMonthDate(0.5), note: "Parking", category: transport),
            Transaction(amount: 90_000, date: currentMonthDate(0.8), note: "Transit card top-up", category: transport),
            Transaction(amount: 55_000, date: daysAgo(20), note: "Toll road", category: transport),
            Transaction(amount: 70_000, date: daysAgo(50), note: "Parking", category: transport),
            Transaction(amount: 40_000, date: daysAgo(80), note: "Ride-hailing", category: transport),
            Transaction(amount: 50_000, date: daysFromNow(5), note: "Weekend trip (planned)", category: transport),

            // Bills & utilities — under its limit.
            Transaction(amount: 350_000, date: currentMonthDate(0.3), note: "Electricity bill", category: billsAndUtilities),
            Transaction(amount: 250_000, date: currentMonthDate(0.6), note: "Internet and phone", category: billsAndUtilities),
            Transaction(amount: 180_000, date: currentMonthDate(0.85), note: "Water bill", category: billsAndUtilities),
            Transaction(amount: 400_000, date: daysAgo(33), note: "Electricity bill", category: billsAndUtilities),
            Transaction(amount: 390_000, date: daysAgo(64), note: "Internet and phone", category: billsAndUtilities),

            // Health — under its limit.
            Transaction(amount: 150_000, date: currentMonthDate(0.25), note: "Pharmacy", category: health),
            Transaction(amount: 120_000, date: currentMonthDate(0.7), note: "Doctor visit copay", category: health),
            Transaction(amount: 200_000, date: daysAgo(45), note: "Dental checkup", category: health),
            Transaction(amount: 90_000, date: daysAgo(90), note: "Pharmacy", category: health),

            // Fun — no limit, so it never carries a budget status beyond "no limit".
            Transaction(amount: 150_000, date: currentMonthDate(0.5), note: "Movie tickets", category: fun),
            Transaction(amount: 250_000, date: daysAgo(25), note: "Concert ticket", category: fun),
            Transaction(amount: 100_000, date: daysAgo(70), note: "Video game", category: fun),

            // Uncategorized spend.
            Transaction(amount: 200_000, date: daysAgo(5), note: "Cash withdrawal", category: nil),
            Transaction(amount: 75_000, date: daysAgo(18), note: "Unrecognized charge", category: nil)
        ]

        transactions.forEach { context.insert($0) }
        save(context)

        return container
    }

    /// About a week of expenses across a handful of categories.
    static func sparseContainer() -> ModelContainer {
        let container = makeContainer()
        let context = container.mainContext

        let categories = standardCategories()
        categories.forEach { context.insert($0) }
        let groceries = categories[0]
        let diningOut = categories[1]
        let transport = categories[2]

        let transactions: [Transaction] = [
            Transaction(amount: 120_000, date: daysAgo(1), note: "Quick grocery run", category: groceries),
            Transaction(amount: 85_000, date: daysAgo(2), note: "Lunch with a coworker", category: diningOut),
            Transaction(amount: 30_000, date: daysAgo(3), note: "Parking", category: transport),
            Transaction(amount: 150_000, date: daysAgo(5), note: "Dinner out", category: diningOut),
            Transaction(amount: 95_000, date: daysAgo(6), note: "Snacks", category: groceries)
        ]

        transactions.forEach { context.insert($0) }
        save(context)

        return container
    }

    /// No expenses yet, but categories already exist — the state a user
    /// sees right after onboarding, before logging their first transaction.
    static func firstLaunchContainer() -> ModelContainer {
        let container = makeContainer()
        let context = container.mainContext

        standardCategories().forEach { context.insert($0) }
        save(context)

        return container
    }

    /// Expenses exist, but every category has been deleted — every
    /// transaction is orphaned and shows up as uncategorized.
    static func noCategoriesContainer() -> ModelContainer {
        let container = makeContainer()
        let context = container.mainContext

        let transactions: [Transaction] = [
            Transaction(amount: 45_000, date: daysAgo(1), note: "Coffee"),
            Transaction(amount: 120_000, date: daysAgo(2), note: "Groceries"),
            Transaction(amount: 60_000, date: daysAgo(4), note: "Parking"),
            Transaction(amount: 200_000, date: daysAgo(9), note: "Dinner out"),
            Transaction(amount: 35_000, date: daysAgo(15), note: "Transit card top-up")
        ]

        transactions.forEach { context.insert($0) }
        save(context)

        return container
    }

    // MARK: - Shared Category Set

    /// The seven categories reused across the "rich", "sparse", and
    /// "first launch" scenarios, matching the app's original design
    /// mockup. Each call returns fresh model instances so scenarios never
    /// share state.
    private static func standardCategories() -> [Category] {
        [
            Category(name: "Groceries", monthlyLimit: 1_500_000, colorToken: "green"),
            Category(name: "Dining out", monthlyLimit: 800_000, colorToken: "orange"),
            Category(name: "Transport", monthlyLimit: 400_000, colorToken: "blue"),
            Category(name: "Bills & utilities", monthlyLimit: 1_200_000, colorToken: "purple"),
            Category(name: "Health", monthlyLimit: 500_000, colorToken: "red"),
            Category(name: "Fun", monthlyLimit: nil, colorToken: "pink"),
            Category(name: "Home", monthlyLimit: 300_000, colorToken: "yellow")
        ]
    }

    // MARK: - Container Factory

    /// Builds a fresh in-memory `ModelContainer` for preview/test use.
    ///
    /// Force-`try!` is intentional and safe here: this only ever runs in
    /// Xcode previews and preview-only tests, neither of which has an
    /// error-recovery path — a failure to construct an in-memory
    /// container from this fixed, hardcoded schema would mean the schema
    /// itself is broken, which should crash loudly at dev time rather
    /// than be silently handled.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }

    /// Saves the freshly inserted fixture data so it's immediately visible
    /// to any other `ModelContext` on the same container (e.g. a `@Query`
    /// in a `#Preview`), rather than only living in this context's
    /// uncommitted changes.
    ///
    /// Force-`try!` for the same reason as `makeContainer()` above: a save
    /// failure here means the fixture data itself is malformed, which
    /// should crash loudly at dev time rather than be handled.
    private static func save(_ context: ModelContext) {
        try! context.save()
    }

    // MARK: - Date Helpers

    /// A date `days` in the past, relative to now.
    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    /// A date `days` in the future, relative to now.
    private static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    /// A date within the *current* calendar month, `fraction` of the way
    /// between the start of the month and now (`0` is the 1st, `1` is
    /// today). Using a fraction of the elapsed month — rather than fixed
    /// day offsets — keeps the "exactly at limit" / "over limit" fixtures
    /// correct no matter what day of the month previews happen to run on.
    private static func currentMonthDate(_ fraction: Double) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let elapsed = now.timeIntervalSince(startOfMonth)
        return startOfMonth.addingTimeInterval(elapsed * fraction)
    }
}
