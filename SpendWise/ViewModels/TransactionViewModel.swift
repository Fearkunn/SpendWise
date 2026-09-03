//
//  TransactionViewModel.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation
import SwiftData
import os

/// Write/action layer for `Transaction`: create, update, and delete
/// expenses with explicit validation.
///
/// This type holds no read state of its own — Views read transactions via
/// `@Query` directly, per the project's MVVM convention. It's
/// `@MainActor`-isolated because it owns a `ModelContext`, which is not
/// `Sendable` and must stay on the actor that created it.
///
/// Month-scoped spend aggregation also lives here, rather than on
/// `CategoryViewModel`, because it queries `Transaction` directly — data
/// locality, not a role label. `CategoryViewModel` consumes the results as
/// parameters (e.g. into `BudgetStatus.evaluate(limit:spent:)`) and never
/// calls into this type.
@Observable
@MainActor
final class TransactionViewModel {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.spendwise.app", category: "TransactionViewModel")

    // MARK: - Initializers

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Validates the given input and inserts a new `Transaction`.
    ///
    /// - Parameters:
    ///   - amountText: Raw amount input; only digit characters are used to
    ///     build the amount, everything else (currency symbols,
    ///     separators, whitespace) is discarded. The parsed result must be
    ///     greater than zero.
    ///   - date: The expense date. `nil` (no date picked yet) is rejected,
    ///     since `Transaction.date` itself isn't optional.
    ///   - note: Free-text note, stored trimmed of leading/trailing
    ///     whitespace. An empty note is valid and stored as-is.
    ///   - category: The category to assign, if any. `nil` is a valid,
    ///     first-class "uncategorized" state.
    /// - Returns: The newly inserted, persisted `Transaction`.
    /// - Throws: `TransactionValidationError` if validation or the save
    ///   itself fails.
    @discardableResult
    func add(amountText: String, date: Date?, note: String, category: Category?) throws -> Transaction {
        let amount = try parsedAmount(from: amountText)
        let validatedDate = try requiredDate(date)

        let transaction = Transaction(
            amount: amount,
            date: validatedDate,
            note: trimmed(note),
            category: category
        )
        modelContext.insert(transaction)

        do {
            try modelContext.save()
        } catch {
            // Roll back the insert so a failed save doesn't leave a
            // half-persisted transaction behind in the context.
            modelContext.delete(transaction)
            logger.error("Failed to save new transaction: \(error.localizedDescription)")
            throw TransactionValidationError.saveFailed(underlying: error)
        }

        return transaction
    }

    // MARK: - Update

    /// Validates the given input and applies it to an existing
    /// `Transaction`, persisting the change.
    ///
    /// - Throws: `TransactionValidationError` if validation or the save
    ///   itself fails. On a save failure, the transaction's in-memory
    ///   properties may still reflect the attempted edit; the caller is
    ///   responsible for deciding how to recover (e.g. re-presenting the
    ///   form).
    func update(_ transaction: Transaction, amountText: String, date: Date?, note: String, category: Category?) throws {
        let amount = try parsedAmount(from: amountText)
        let validatedDate = try requiredDate(date)

        transaction.amount = amount
        transaction.date = validatedDate
        transaction.note = trimmed(note)
        transaction.category = category

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save transaction update: \(error.localizedDescription)")
            throw TransactionValidationError.saveFailed(underlying: error)
        }
    }

    // MARK: - Delete

    /// Deletes a `Transaction` and persists the removal.
    ///
    /// - Throws: `TransactionValidationError.saveFailed` if the deletion
    ///   can't be persisted.
    func delete(_ transaction: Transaction) throws {
        modelContext.delete(transaction)

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save transaction deletion: \(error.localizedDescription)")
            throw TransactionValidationError.saveFailed(underlying: error)
        }
    }

    // MARK: - Aggregation

    /// Every expense in the calendar month containing `month`, categorized
    /// or not.
    ///
    /// - Parameter month: Any date within the target month; only its
    ///   year/month component is used — the day is irrelevant.
    /// - Throws: If the underlying fetch fails.
    func monthTotal(in month: Date) throws -> Int {
        try transactions(in: month).reduce(0) { $0 + $1.amount }
    }

    /// Spend attributed to a single category within the calendar month
    /// containing `month`.
    ///
    /// - Parameters:
    ///   - month: Any date within the target month; only its year/month
    ///     component is used — the day is irrelevant.
    ///   - categoryID: The persistent identifier of the category to sum
    ///     spend for.
    /// - Throws: If the underlying fetch fails.
    func spent(in month: Date, categoryID: PersistentIdentifier) throws -> Int {
        try transactions(in: month)
            .filter { $0.category?.persistentModelID == categoryID }
            .reduce(0) { $0 + $1.amount }
    }

    /// Spend in the calendar month containing `month` that isn't
    /// attributed to any live category.
    ///
    /// Derived as `monthTotal(in:)` minus the sum of `spent(in:categoryID:)`
    /// across every currently-existing `Category` — deliberately *not* by
    /// filtering transactions for `category == nil`. The two look
    /// equivalent but aren't: the subtraction form is correct by
    /// construction, since it reconciles against the month total rather
    /// than depending on enumerating which categories exist lining up
    /// exactly with each transaction's live `category` reference.
    ///
    /// - Parameter month: Any date within the target month; only its
    ///   year/month component is used — the day is irrelevant.
    /// - Throws: If the underlying fetch fails.
    func uncategorizedTotal(in month: Date) throws -> Int {
        let total = try monthTotal(in: month)

        let categories: [Category]
        do {
            categories = try modelContext.fetch(FetchDescriptor<Category>())
        } catch {
            logger.error("Failed to fetch categories for uncategorized-total aggregation: \(error.localizedDescription)")
            throw error
        }

        let categorizedSpend = try categories.reduce(0) { partial, category in
            try partial + spent(in: month, categoryID: category.persistentModelID)
        }

        return total - categorizedSpend
    }

    // MARK: - Aggregation Helpers

    /// Every transaction dated within the calendar month containing
    /// `month`, using the device's current calendar to determine month
    /// boundaries.
    ///
    /// The upper bound is exclusive, so a transaction dated exactly at the
    /// start of the *next* month is correctly excluded.
    private func transactions(in month: Date) throws -> [Transaction] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        let start = interval.start
        let end = interval.end

        let predicate = #Predicate<Transaction> { transaction in
            transaction.date >= start && transaction.date < end
        }
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch transactions for month aggregation: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Validation Helpers

    /// Parses digits-only input into a positive whole Rupiah amount.
    ///
    /// Non-digit characters are discarded before parsing. Negative
    /// amounts aren't representable this way by design — the sign
    /// character is filtered out along with everything else non-numeric.
    private func parsedAmount(from text: String) throws -> Int {
        let digitsOnly = text.filter(\.isNumber)
        guard let amount = Int(digitsOnly), amount > 0 else {
            throw TransactionValidationError.invalidAmount
        }
        return amount
    }

    /// Requires a non-nil date, since `Transaction.date` isn't optional.
    private func requiredDate(_ date: Date?) throws -> Date {
        guard let date else {
            throw TransactionValidationError.missingDate
        }
        return date
    }

    /// Trims leading/trailing whitespace and newlines. An empty result is
    /// a valid, stored-as-is note — no placeholder text is substituted
    /// here; that's a View-layer display concern.
    private func trimmed(_ note: String) -> String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
