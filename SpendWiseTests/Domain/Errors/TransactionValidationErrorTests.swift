//
//  TransactionValidationErrorTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `TransactionValidationError.errorDescription`'s copy — in
/// particular the exact save-failure string the design mockup specifies
/// (`Design/SpendWise.dc.html`'s `shouldFail('save')` branch), which
/// `ExpenseSheetView`'s inline error banner surfaces verbatim (#19).
struct TransactionValidationErrorTests {

    @Test func invalidAmountDescribesTheAmountRequirement() {
        #expect(TransactionValidationError.invalidAmount.errorDescription == "Enter an amount greater than Rp0.")
    }

    @Test func missingDateAsksForADate() {
        #expect(TransactionValidationError.missingDate.errorDescription == "Pick a date for this expense.")
    }

    @Test func saveFailedMatchesTheMockupsSaveFailureCopy() {
        let underlying = NSError(domain: "test", code: 1)

        #expect(
            TransactionValidationError.saveFailed(underlying: underlying).errorDescription
                == "Couldn't save — the change is still on this device only. Try again."
        )
    }
}
