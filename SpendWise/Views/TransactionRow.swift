//
//  TransactionRow.swift
//  SpendWise
//

import SwiftUI

/// A single expense row on the Transactions screen: a category color dot,
/// the note (or a muted em-dash when there isn't one), the category name
/// and row date, and the amount right-aligned.
struct TransactionRow: View {

    // MARK: - Properties

    let transaction: Transaction

    private let dotDiameter: CGFloat = 9
    private let dotCornerRadius: CGFloat = 3

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            colorDot

            VStack(alignment: .leading, spacing: 2) {
                Text(noteText)
                    .font(.body)
                    .foregroundStyle(transaction.note.isEmpty ? .secondary : .primary)

                categoryAndDateLine
            }

            Spacer(minLength: 8)

            Text(RupiahFormatter.string(from: transaction.amount))
                .font(.callout.monospacedDigit())
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Subviews

    /// A filled, softly-rounded square in the category's color, or — for an
    /// uncategorized transaction — a dashed hollow outline of the same
    /// shape, matching the mockup's visual distinction between "has a
    /// category" and "doesn't." (The mockup uses a rounded square here, not
    /// a circle.)
    @ViewBuilder
    private var colorDot: some View {
        if let category = transaction.category {
            RoundedRectangle(cornerRadius: dotCornerRadius)
                .fill(CategoryColor.color(forToken: category.colorToken))
                .frame(width: dotDiameter, height: dotDiameter)
        } else {
            RoundedRectangle(cornerRadius: dotCornerRadius)
                .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                .frame(width: dotDiameter, height: dotDiameter)
        }
    }

    private var categoryAndDateLine: some View {
        HStack(spacing: 4) {
            Text(categoryName)
                // Uncategorized rows show "Uncategorized" in a lighter
                // weight and color than a real category name, per #12's
                // mockup.
                .fontWeight(transaction.category == nil ? .regular : .medium)
                .foregroundStyle(transaction.category == nil ? .tertiary : .secondary)

            Text("·")
                .foregroundStyle(.tertiary)

            Text(DateLabelFormatter.rowDate(for: transaction.date))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    // MARK: - Derived Text

    /// The note text, or a grey em-dash when the note is empty — this
    /// codebase's established convention (from #7) instead of a placeholder
    /// string like "Uncategorized expense". The category name already
    /// appears on the line beneath, so it isn't repeated here.
    private var noteText: String {
        transaction.note.isEmpty ? "—" : transaction.note
    }

    private var categoryName: String {
        transaction.category?.name ?? "Uncategorized"
    }
}

// MARK: - Previews

#Preview {
    let groceries = Category(name: "Groceries", colorToken: "green")

    return List {
        TransactionRow(transaction: Transaction(amount: 450_000, date: .now, note: "Weekly groceries", category: groceries))
        TransactionRow(transaction: Transaction(amount: 45_000, date: .now, note: "", category: groceries))
        TransactionRow(transaction: Transaction(amount: 200_000, date: .now, note: "Cash withdrawal", category: nil))
        TransactionRow(transaction: Transaction(amount: 75_000, date: .now, note: "", category: nil))
    }
}
