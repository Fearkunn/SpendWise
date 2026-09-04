//
//  ExpenseNoteHintTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `ExpenseNoteHint.text(note:hasCategory:)`: no hint once the note
/// has content, and copy that differs based on whether a category is
/// selected while it's blank.
struct ExpenseNoteHintTests {

    @Test func blankNoteWithNoCategorySelectedExplainsItReadsAsUncategorized() {
        let text = ExpenseNoteHint.text(note: "", hasCategory: false)
        #expect(text == "Left blank, the row shows a dash and reads as Uncategorized underneath.")
    }

    @Test func blankNoteWithACategorySelectedPointsToTheCategoryNameInstead() {
        let text = ExpenseNoteHint.text(note: "", hasCategory: true)
        #expect(text == "Left blank, the row shows a dash — the category name already sits underneath it.")
    }

    @Test func whitespaceOnlyNoteCountsAsBlank() {
        let text = ExpenseNoteHint.text(note: "   ", hasCategory: false)
        #expect(!text.isEmpty)
    }

    @Test func noteWithContentProducesNoHint() {
        let text = ExpenseNoteHint.text(note: "Coffee", hasCategory: false)
        #expect(text.isEmpty)
    }
}
