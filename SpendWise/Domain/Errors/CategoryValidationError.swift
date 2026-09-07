//
//  CategoryValidationError.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// Errors produced while validating or persisting a `Category` through
/// `CategoryViewModel`.
///
/// Every case carries a user-facing message via `LocalizedError`, so a View
/// can surface `error.localizedDescription` directly without re-deriving
/// copy for each failure.
enum CategoryValidationError: LocalizedError {

    // MARK: - Cases

    /// The name was empty after trimming whitespace.
    case missingName

    /// Another category already has this name, compared case-insensitively.
    case duplicateName(name: String)

    /// The underlying `ModelContext` failed to persist an add or update.
    case saveFailed(underlying: Error)

    /// The underlying `ModelContext` failed to persist a deletion.
    case deleteFailed(underlying: Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .missingName:
            return "Enter a name for this category."
        case .duplicateName(let name):
            return "\"\(name)\" already exists. Two categories with the same name make the picker ambiguous."
        case .saveFailed:
            return "Couldn't save — the change is still on this device only. Try again."
        case .deleteFailed:
            return "Couldn't delete — nothing has changed. Try again."
        }
    }
}
