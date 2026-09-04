//
//  CategoryColor.swift
//  SpendWise
//

import SwiftUI

/// Maps a `Category.colorToken` to the `Color` it should render with.
///
/// Per `Category.colorToken`'s doc comment and `BudgetBar`'s precedent,
/// this mapping is a View-layer concern, not something the model or a
/// ViewModel knows about. This is the first place in the app that actually
/// needs to perform the mapping (`BudgetBar` takes an already-resolved
/// `Color` from its caller), so it lives here as the one shared
/// implementation for every screen that renders a category's color —
/// starting with the Transactions screen's row color dot.
enum CategoryColor {

    // MARK: - Methods

    /// The `Color` for a given `colorToken`, matching
    /// `CategoryViewModel.colorPalette`'s eight token names. An unrecognized
    /// token (which shouldn't occur given categories are only ever created
    /// through `CategoryViewModel.add`) falls back to `.gray` rather than
    /// crashing.
    static func color(forToken token: String) -> Color {
        switch token {
        case "blue": .blue
        case "green": .green
        case "orange": .orange
        case "red": .red
        case "purple": .purple
        case "pink": .pink
        case "yellow": .yellow
        case "teal": .teal
        default: .gray
        }
    }
}
