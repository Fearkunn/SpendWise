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

    // MARK: - Private

    /// Fixed to `id_ID` regardless of the device's actual locale. IDR has
    /// zero minor units under ISO 4217, so this locale/currency pairing
    /// already produces grouped, whole-number output with no extra
    /// rounding logic needed.
    private static let locale = Locale(identifier: "id_ID")
}
