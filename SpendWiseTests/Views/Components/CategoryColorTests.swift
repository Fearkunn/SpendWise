//
//  CategoryColorTests.swift
//  SpendWiseTests
//

import Testing
import SwiftUI
@testable import SpendWise

/// Covers `CategoryColor.color(forToken:)` — a pure string-to-`Color`
/// mapping, so it's tested directly like `DateLabelFormatter`/
/// `RupiahFormatter`'s other pure Domain/View-layer helpers.
struct CategoryColorTests {

    @Test func mapsEveryTokenInTheCategoryViewModelPaletteToADistinctColor() {
        let colors = CategoryViewModel.colorPalette.map(CategoryColor.color(forToken:))

        // Matches the real `Category*` color set assets (#41) that back
        // this mapping, rather than the earlier bare system colors.
        #expect(colors == [
            Color("CategoryBlue"),
            Color("CategoryGreen"),
            Color("CategoryOrange"),
            Color("CategoryRed"),
            Color("CategoryPurple"),
            Color("CategoryPink"),
            Color("CategoryYellow"),
            Color("CategoryTeal")
        ])
    }

    @Test func unrecognizedTokenFallsBackToGrayRatherThanCrashing() {
        #expect(CategoryColor.color(forToken: "not-a-real-token") == .gray)
    }
}
