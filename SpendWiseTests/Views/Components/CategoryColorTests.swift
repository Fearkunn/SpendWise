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

        #expect(colors == [.blue, .green, .orange, .red, .purple, .pink, .yellow, .teal])
    }

    @Test func unrecognizedTokenFallsBackToGrayRatherThanCrashing() {
        #expect(CategoryColor.color(forToken: "not-a-real-token") == .gray)
    }
}
