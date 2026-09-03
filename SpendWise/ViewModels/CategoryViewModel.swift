//
//  CategoryViewModel.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation
import SwiftData
import os

/// Write/action layer for `Category`: create, update, and delete categories,
/// with name and limit validation and color assignment.
///
/// This type holds no read state of its own — Views read categories via
/// `@Query` directly, per the project's MVVM convention. It's
/// `@MainActor`-isolated because it owns a `ModelContext`, which is not
/// `Sendable` and must stay on the actor that created it.
///
/// Per CLAUDE.md's cross-entity ownership rule, this type does not depend
/// on, inject, or hold a reference to `TransactionViewModel`. `budgetStatus`
/// below is a pure pass-through to `BudgetStatus.evaluate(limit:spent:)`;
/// the View is responsible for supplying `spent` from
/// `TransactionViewModel`. Delete relies entirely on `Category.transactions`'s
/// `.nullify` delete rule — this type never touches `Transaction`.
@Observable
@MainActor
final class CategoryViewModel {

    // MARK: - Palette

    /// The 8 color tokens new categories are auto-assigned from, in
    /// priority order. Mapping a token to an actual color is a View-layer
    /// concern — see `Category.colorToken`'s doc comment.
    static let colorPalette: [String] = [
        "blue", "green", "orange", "red", "purple", "pink", "yellow", "teal"
    ]

    // MARK: - Properties

    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.spendwise.app", category: "CategoryViewModel")

    // MARK: - Initializers

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Validates the given input and inserts a new `Category`.
    ///
    /// - Parameters:
    ///   - name: The category's display name. Required after trimming
    ///     leading/trailing whitespace; rejected as a duplicate if another
    ///     category already has the same name, compared
    ///     case-insensitively.
    ///   - monthlyLimitText: Raw limit input; only digit characters are
    ///     used to build the limit. Empty input, non-digit input, and an
    ///     input of exactly `0` all normalize to `nil` ("no limit") — see
    ///     `normalizedLimit(from:)`.
    /// - Returns: The newly inserted, persisted `Category`, auto-assigned
    ///   the first unused color from `colorPalette`.
    /// - Throws: `CategoryValidationError` if validation or the save itself
    ///   fails.
    @discardableResult
    func add(name: String, monthlyLimitText: String) throws -> Category {
        let validatedName = try requiredName(name)
        try ensureNameIsUnique(validatedName, excluding: nil)
        let limit = normalizedLimit(from: monthlyLimitText)

        let category = Category(
            name: validatedName,
            monthlyLimit: limit,
            colorToken: try nextColorToken()
        )
        modelContext.insert(category)

        do {
            try modelContext.save()
        } catch {
            // Roll back the insert so a failed save doesn't leave a
            // half-persisted category behind in the context.
            modelContext.delete(category)
            logger.error("Failed to save new category: \(error.localizedDescription)")
            throw CategoryValidationError.saveFailed(underlying: error)
        }

        return category
    }

    // MARK: - Update

    /// Validates the given input and applies it to an existing `Category`,
    /// persisting the change.
    ///
    /// The category's `colorToken` is left untouched — auto-assignment
    /// only happens for new categories, per the issue's scope.
    ///
    /// - Throws: `CategoryValidationError` if validation or the save itself
    ///   fails. On a save failure, the category's in-memory properties may
    ///   still reflect the attempted edit; the caller is responsible for
    ///   deciding how to recover (e.g. re-presenting the form).
    func update(_ category: Category, name: String, monthlyLimitText: String) throws {
        let validatedName = try requiredName(name)
        try ensureNameIsUnique(validatedName, excluding: category)
        let limit = normalizedLimit(from: monthlyLimitText)

        category.name = validatedName
        category.monthlyLimit = limit

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save category update: \(error.localizedDescription)")
            throw CategoryValidationError.saveFailed(underlying: error)
        }
    }

    // MARK: - Delete

    /// Deletes a `Category` and persists the removal.
    ///
    /// This does not — and must not — touch `Transaction` in any way.
    /// `Category.transactions`'s `deleteRule: .nullify` (see #3) is what
    /// turns each affected transaction's `category` into `nil` once this
    /// save completes; that guarantee lives entirely at the model layer.
    ///
    /// - Throws: `CategoryValidationError.saveFailed` if the deletion can't
    ///   be persisted.
    func delete(_ category: Category) throws {
        modelContext.delete(category)

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save category deletion: \(error.localizedDescription)")
            throw CategoryValidationError.saveFailed(underlying: error)
        }
    }

    // MARK: - Budget Status

    /// Determines how a category's spending compares to its monthly limit.
    ///
    /// A pure pass-through to `BudgetStatus.evaluate(limit:spent:)` — no
    /// new logic lives here. `nonisolated` because this needs no access to
    /// `modelContext` or any other actor-isolated state; per CLAUDE.md's
    /// cross-entity ownership rule, the View calls `TransactionViewModel`
    /// to get `spent` and passes it in here rather than this type querying
    /// `Transaction` itself.
    nonisolated func budgetStatus(limit: Int?, spent: Int) -> BudgetStatus {
        BudgetStatus.evaluate(limit: limit, spent: spent)
    }

    // MARK: - Validation Helpers

    /// Requires a non-empty name after trimming leading/trailing
    /// whitespace and newlines.
    private func requiredName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CategoryValidationError.missingName
        }
        return trimmed
    }

    /// Rejects `name` if another existing category already has it,
    /// compared case-insensitively. `categoryToExclude` lets an update
    /// exempt the category being edited, so renaming a category to its own
    /// current name isn't flagged as a false duplicate.
    private func ensureNameIsUnique(_ name: String, excluding categoryToExclude: Category?) throws {
        let existingCategories: [Category]
        do {
            existingCategories = try modelContext.fetch(FetchDescriptor<Category>())
        } catch {
            logger.error("Failed to fetch categories for duplicate-name validation: \(error.localizedDescription)")
            throw error
        }

        let isDuplicate = existingCategories.contains { existing in
            guard existing !== categoryToExclude else { return false }
            return existing.name.caseInsensitiveCompare(name) == .orderedSame
        }

        if isDuplicate {
            throw CategoryValidationError.duplicateName(name: name)
        }
    }

    /// Parses digits-only input into a monthly limit.
    ///
    /// Non-digit characters are discarded before parsing (negative limits
    /// aren't representable this way by design, matching
    /// `TransactionViewModel`'s amount parsing). Empty input and
    /// non-numeric input both fall through to `nil`.
    ///
    /// **Zero-limit rule**: an input that parses to exactly `0` also
    /// normalizes to `nil`, not an enforceable zero limit. This is a
    /// deliberate design decision, not an oversight — see the issue's
    /// "Monthly limit — zero-limit rule" section. A category must never be
    /// created that flips to "over budget" the instant any amount is spent
    /// against it; almost nobody entering `Rp0` means "budget exactly
    /// zero," they mean "don't track a limit here."
    private func normalizedLimit(from text: String) -> Int? {
        let digitsOnly = text.filter(\.isNumber)
        guard let limit = Int(digitsOnly), limit > 0 else {
            return nil
        }
        return limit
    }

    /// The first color in `colorPalette` not already assigned to an
    /// existing category. If all 8 are in use, falls back to cycling by
    /// index (`existingCount % colorPalette.count`).
    private func nextColorToken() throws -> String {
        let existingCategories: [Category]
        do {
            existingCategories = try modelContext.fetch(FetchDescriptor<Category>())
        } catch {
            logger.error("Failed to fetch categories for color assignment: \(error.localizedDescription)")
            throw error
        }

        let usedTokens = Set(existingCategories.map(\.colorToken))
        if let firstUnused = Self.colorPalette.first(where: { !usedTokens.contains($0) }) {
            return firstUnused
        }

        return Self.colorPalette[existingCategories.count % Self.colorPalette.count]
    }
}
