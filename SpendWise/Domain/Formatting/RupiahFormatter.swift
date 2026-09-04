//
//  RupiahFormatter.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// Formats whole-number Rupiah amounts for display.
///
/// SpendWise only ever displays amounts in Indonesian Rupiah — this is a
/// fixed product decision, not something that should follow the device's
/// locale. Callers never need to pass a currency or locale in; there is
/// exactly one way amounts are shown in this app.
enum RupiahFormatter {

    // MARK: - Methods

    /// Formats `amount` as e.g. `Rp1.350.000`.
    ///
    /// The sign of `amount` is ignored — negative amounts are formatted as
    /// their absolute value. The design never shows a minus sign; an
    /// over-budget state is communicated by a text label ("OVER BUDGET BY")
    /// supplied by the caller, not by this formatter.
    static func string(from amount: Int) -> String {
        abs(amount).formatted(.currency(code: "IDR").locale(locale))
    }

    /// Formats raw amount input into thousands-grouped digits for live
    /// display while the amount field is being typed into — e.g.
    /// `"1350000"` → `"1.350.000"` — with no `Rp` prefix or currency
    /// symbol, since the expense sheet renders those as a separate, static
    /// label next to the field.
    ///
    /// Non-digit characters are discarded before formatting, the same way
    /// `TransactionViewModel.add(amountText:...)` discards them, so what's
    /// displayed always matches what will actually be parsed on save. This
    /// method performs no validation of its own (e.g. it happily formats
    /// `"0"`); the amount is still only accepted or rejected by
    /// `TransactionViewModel`'s own parsing when the sheet is saved.
    ///
    /// - Returns: The grouped digits, or an empty string if `text` contains
    ///   no digits at all.
    static func groupedDigits(from text: String) -> String {
        let digitsOnly = text.filter(\.isNumber)
        guard let amount = Int(digitsOnly) else { return "" }
        return amount.formatted(.number.locale(locale))
    }

    // MARK: - Private

    /// Fixed to `id_ID` regardless of the device's actual locale. IDR has
    /// zero minor units under ISO 4217, so this locale/currency pairing
    /// already produces grouped, whole-number output with no extra
    /// rounding logic needed.
    private static let locale = Locale(identifier: "id_ID")
}
