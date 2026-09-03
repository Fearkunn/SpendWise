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
/// Aggregation (e.g. spend-against-budget) is intentionally out of scope
/// here; it belongs to a separate method added later.
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
