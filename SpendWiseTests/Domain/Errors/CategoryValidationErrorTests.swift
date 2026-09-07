//
//  CategoryValidationErrorTests.swift
//  SpendWiseTests
//

import Testing
import Foundation
@testable import SpendWise

/// Covers `CategoryValidationError.errorDescription`'s copy — in particular
/// the exact save- and delete-failure strings the design mockup specifies
/// (`Design/SpendWise.dc.html`'s `shouldFail('save')` and `shouldFail('delcat')`
/// branches), which `CategorySheetView`'s inline error banner and
/// `CategoryDeleteConfirmationView`'s inline error block surface verbatim
/// (#19). `.saveFailed` and `.deleteFailed` are deliberately distinct cases
/// with distinct copy — `CategoryViewModel.delete(_:)` must never reuse
/// `.saveFailed` for a delete failure.
struct CategoryValidationErrorTests {

    @Test func missingNameAsksForAName() {
        #expect(CategoryValidationError.missingName.errorDescription == "Enter a name for this category.")
    }

    @Test func duplicateNameNamesTheConflictingCategory() {
        #expect(
            CategoryValidationError.duplicateName(name: "Groceries").errorDescription
                == "\"Groceries\" already exists. Two categories with the same name make the picker ambiguous."
        )
    }

    @Test func saveFailedMatchesTheMockupsSaveFailureCopy() {
        let underlying = NSError(domain: "test", code: 1)

        #expect(
            CategoryValidationError.saveFailed(underlying: underlying).errorDescription
                == "Couldn't save — the change is still on this device only. Try again."
        )
    }

    @Test func deleteFailedMatchesTheMockupsDeleteFailureCopyAndDiffersFromSaveFailed() {
        let underlying = NSError(domain: "test", code: 1)

        #expect(
            CategoryValidationError.deleteFailed(underlying: underlying).errorDescription
                == "Couldn't delete — nothing has changed. Try again."
        )
        #expect(
            CategoryValidationError.deleteFailed(underlying: underlying).errorDescription
                != CategoryValidationError.saveFailed(underlying: underlying).errorDescription
        )
    }
}
