//
//  ExpenseNoteHint.swift
//  SpendWise
//

import Foundation

/// The hint line shown under the expense sheet's note field when it's left
/// blank, wording it differently depending on whether a category is
/// selected — since an uncategorized row has nothing else underneath its
/// note to explain the blank, while a categorized row already shows the
/// category name there.
enum ExpenseNoteHint {

    // MARK: - Text

    /// - Parameters:
    ///   - note: The draft note's current text, as typed.
    ///   - hasCategory: Whether a category (anything other than `None`) is
    ///     currently selected.
    /// - Returns: The hint text, or an empty string once the note has any
    ///   non-whitespace content (no hint is shown at all in that case).
    static func text(note: String, hasCategory: Bool) -> String {
        guard note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        return hasCategory
            ? "Left blank, the row shows a dash — the category name already sits underneath it."
            : "Left blank, the row shows a dash and reads as Uncategorized underneath."
    }
}
