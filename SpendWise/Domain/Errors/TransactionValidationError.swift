//
//  TransactionValidationError.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// Errors produced while validating or persisting a `Transaction` through
/// `TransactionViewModel`.
///
/// Every case carries a user-facing message via `LocalizedError`, so a View
/// can surface `error.localizedDescription` directly without re-deriving
/// copy for each failure.
enum TransactionValidationError: LocalizedError {

    // MARK: - Cases

    /// The amount didn't parse to a whole number greater than zero.
    case invalidAmount

    /// No date was supplied for the expense.
    case missingDate

    /// The underlying `ModelContext` failed to persist the change.
    case saveFailed(underlying: Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Enter an amount greater than Rp0."
        case .missingDate:
            return "Pick a date for this expense."
        case .saveFailed:
            return "Something went wrong while saving. Please try again."
        }
    }
}
