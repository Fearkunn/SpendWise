//
//  CategoryRow.swift
//  SpendWise
//

import SwiftUI

/// A single row on the Categories screen (#15): a color dot, the category's
/// name, its spend for the selected month, and — depending on whether it
/// has a monthly limit — either a progress bar with a short status label,
/// or a plain "no limit" caption.
///
/// This view is presentation-only, matching `TransactionRow`'s precedent:
/// it consumes an already-computed `spent` amount and `status` rather than
/// querying `Transaction` or reclassifying the category's limit itself.
/// Per CLAUDE.md's cross-entity ownership rule, `CategoriesView` is
/// responsible for calling `TransactionViewModel` for `spent` and
/// `CategoryViewModel.budgetStatus(limit:spent:)` for `status`, and passing
/// both in here. Tap-to-edit and swipe-to-delete are also the caller's
/// responsibility (`TransactionDayGroupSection`'s precedent), so this view
/// stays free of behavior.
struct CategoryRow: View {

    // MARK: - Properties

    let category: Category
    let spent: Int
    let status: BudgetStatus

    private let dotDiameter: CGFloat = 11
    private let dotCornerRadius: CGFloat = 4

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: dotCornerRadius)
                    .fill(categoryColor)
                    .frame(width: dotDiameter, height: dotDiameter)

                Text(category.name)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(Color("AppInk"))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                amountColumn
            }

            limitDetail
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var amountColumn: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(RupiahFormatter.string(from: spent))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(amountColor)

            Text(CategoryBudgetRowText.limitCaption(limit: category.monthlyLimit))
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundStyle(Color("AppInk").opacity(0.34))
        }
    }

    @ViewBuilder
    private var limitDetail: some View {
        if let limit = category.monthlyLimit {
            HStack(spacing: 12) {
                BudgetBar(status: status, fraction: fraction(limit: limit), categoryColor: categoryColor, style: .categories)

                Text(CategoryBudgetRowText.statusLabel(status: status, limit: limit, spent: spent))
                    .font(.system(size: 9.5, weight: statusWeight, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(statusColor)
                    .fixedSize()
            }
            .padding(.leading, 23)
        } else {
            Text("NO LIMIT · AMOUNT ONLY")
                .font(.system(size: 9.5, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(Color("AppInk").opacity(0.32))
                .padding(.leading, 23)
        }
    }

    // MARK: - Derived Styling

    private var categoryColor: Color {
        CategoryColor.color(forToken: category.colorToken)
    }

    /// The category's own color for `.under`, or the shared status color
    /// for `.atLimit`/`.over` — matching `BudgetBar`'s own fill-color
    /// derivation, since this is the same visual language applied to text.
    private var highlightColor: Color {
        switch status {
        case .over:
            Color("BudgetOver")
        case .atLimit:
            Color("BudgetAtLimit")
        case .under, .noLimit:
            categoryColor
        }
    }

    private var isHighlighted: Bool {
        status == .over || status == .atLimit
    }

    private var amountColor: Color {
        isHighlighted ? highlightColor : Color("AppInk")
    }

    private var statusColor: Color {
        isHighlighted ? highlightColor : Color("AppInk").opacity(0.38)
    }

    private var statusWeight: Font.Weight {
        isHighlighted ? .semibold : .regular
    }

    // MARK: - Derived Values

    private func fraction(limit: Int) -> Double {
        guard limit > 0 else { return 0 }
        return Double(spent) / Double(limit)
    }
}

// MARK: - Previews

#Preview {
    List {
        CategoryRow(
            category: Category(name: "Groceries", monthlyLimit: 1_500_000, colorToken: "green"),
            spent: 1_500_000,
            status: .atLimit
        )
        CategoryRow(
            category: Category(name: "Dining out", monthlyLimit: 800_000, colorToken: "orange"),
            spent: 950_000,
            status: .over
        )
        CategoryRow(
            category: Category(name: "Transport", monthlyLimit: 400_000, colorToken: "blue"),
            spent: 250_000,
            status: .under
        )
        CategoryRow(
            category: Category(name: "Home", monthlyLimit: 300_000, colorToken: "yellow"),
            spent: 0,
            status: .under
        )
        CategoryRow(
            category: Category(name: "Fun", monthlyLimit: nil, colorToken: "pink"),
            spent: 150_000,
            status: .noLimit
        )
    }
}
