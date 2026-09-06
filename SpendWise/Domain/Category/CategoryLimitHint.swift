//
//  CategoryLimitHint.swift
//  SpendWise
//

import Foundation

/// The hint copy and "Clear" action state shown under the category sheet's
/// monthly limit field, both driven by the same question: does the raw
/// draft text currently contain any digits?
///
/// The hint copy is not decorative — per #16, disclosing that `Rp0` is
/// saved as no limit is how `CategoryViewModel.add`/`update`'s zero-limit
/// normalization rule gets communicated to the user, so the exact wording
/// below is load-bearing and must stay in sync with that rule.
enum CategoryLimitHint {

    // MARK: - Hint Text

    /// - Parameter limitText: The draft limit field's raw text, exactly as
    ///   typed (before `CategoryViewModel`'s own digit-only normalization).
    /// - Returns: The "with a limit" copy once any digit has been entered,
    ///   or the "no limit" copy while the field is empty/non-numeric —
    ///   matching `CategoryViewModel.normalizedLimit(from:)`'s own
    ///   digits-only reading of the same text.
    static func text(limitText: String) -> String {
        hasDigits(limitText)
            ? "Repeats every month. Spending past it never blocks anything — it just shows as over. Rp0 is saved as no limit."
            : "No limit is a normal setup: spending is tracked and totalled, with no bar or percentage."
    }

    // MARK: - Clear Action

    /// Whether the "Clear" action next to the limit field should be enabled
    /// (full-strength) rather than dimmed. It's only meaningful once the
    /// field actually has something to clear.
    static func isClearEnabled(limitText: String) -> Bool {
        hasDigits(limitText)
    }

    // MARK: - Private

    private static func hasDigits(_ text: String) -> Bool {
        text.contains { $0.isNumber }
    }
}
