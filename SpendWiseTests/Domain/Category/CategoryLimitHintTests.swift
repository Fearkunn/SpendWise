//
//  CategoryLimitHintTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `CategoryLimitHint`: hint copy selection and "Clear" enabled
/// state, both driven by whether the draft limit text contains any digits.
struct CategoryLimitHintTests {

    // MARK: - Hint Text

    @Test func emptyLimitTextProducesTheNoLimitHint() {
        let text = CategoryLimitHint.text(limitText: "")
        #expect(text == "No limit is a normal setup: spending is tracked and totalled, with no bar or percentage.")
    }

    @Test func nonDigitLimitTextProducesTheNoLimitHint() {
        let text = CategoryLimitHint.text(limitText: "Rp")
        #expect(text == "No limit is a normal setup: spending is tracked and totalled, with no bar or percentage.")
    }

    @Test func limitTextWithDigitsProducesTheWithLimitHintDisclosingTheZeroRule() {
        let text = CategoryLimitHint.text(limitText: "500.000")
        #expect(text == "Repeats every month. Spending past it never blocks anything — it just shows as over. Rp0 is saved as no limit.")
    }

    @Test func aSingleZeroDigitStillProducesTheWithLimitHint() {
        // The hint has to disclose the zero-limit rule *before* save, so it
        // reacts to "does this look like limit input" rather than
        // pre-empting `CategoryViewModel.normalizedLimit(from:)`'s own
        // zero-to-nil normalization.
        let text = CategoryLimitHint.text(limitText: "0")
        #expect(text == "Repeats every month. Spending past it never blocks anything — it just shows as over. Rp0 is saved as no limit.")
    }

    // MARK: - Clear Action

    @Test func clearIsDisabledWhenTheFieldIsEmpty() {
        #expect(CategoryLimitHint.isClearEnabled(limitText: "") == false)
    }

    @Test func clearIsDisabledWhenTheFieldHasOnlyNonDigitCharacters() {
        #expect(CategoryLimitHint.isClearEnabled(limitText: "Rp") == false)
    }

    @Test func clearIsEnabledOnceTheFieldHasAnyDigit() {
        #expect(CategoryLimitHint.isClearEnabled(limitText: "500.000") == true)
    }
}
