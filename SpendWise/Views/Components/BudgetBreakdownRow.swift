//
//  BudgetBreakdownRow.swift
//  SpendWise
//

import SwiftUI

/// A single row on the Budget screen's (#18) by-category breakdown: a color
/// dot, the category's name, its spend for the selected month, and —
/// depending on whether it has a monthly limit — either a bar with a status
/// line, or a plain "no limit" caption.
///
/// Presentation-only, mirroring `CategoryRow`'s precedent for the Categories
/// screen: it consumes an already-computed `spent` amount and `status`
/// rather than querying `Transaction` or reclassifying the category's limit
/// itself. Per CLAUDE.md's cross-entity ownership rule, `BudgetView` is
/// responsible for calling `TransactionViewModel` for `spent` and
/// `CategoryViewModel.budgetStatus(limit:spent:)` for `status`, and passing
/// both in here.
struct BudgetBreakdownRow: View {

    // MARK: - Properties

    let category: Category
    let spent: Int
    let status: BudgetStatus

    private let dotDiameter: CGFloat = 9
    private let dotCornerRadius: CGFloat = 3

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 11) {
                RoundedRectangle(cornerRadius: dotCornerRadius)
                    .fill(categoryColor)
                    .frame(width: dotDiameter, height: dotDiameter)

                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppInk"))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text(RupiahFormatter.string(from: spent))
                    .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(amountColor)
            }

            limitDetail
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var limitDetail: some View {
        if let limit = category.monthlyLimit {
            VStack(alignment: .leading, spacing: 6) {
                BudgetBar(status: status, fraction: fraction(limit: limit), categoryColor: categoryColor, style: .budget)

                HStack(alignment: .firstTextBaseline) {
                    Text(BudgetBreakdownRowText.statusText(status: status, limit: limit, spent: spent))
                        .font(.system(size: 10, weight: statusWeight, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(statusColor)

                    Spacer(minLength: 10)

                    Text(BudgetBreakdownRowText.limitText(limit: limit))
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(Color("AppInk").opacity(0.36))
                }
            }
        } else {
            Text("NO LIMIT SET · TRACKED ONLY")
                .font(.system(size: 10, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(Color("AppInk").opacity(0.34))
        }
    }

    // MARK: - Derived Styling

    private var categoryColor: Color {
        CategoryColor.color(forToken: category.colorToken)
    }

    /// The shared over/at-limit status color for a highlighted row, or the
    /// category's own color otherwise — matching `BudgetBar`'s identical
    /// fill-color derivation, since this is the same visual language
    /// applied to text.
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
        isHighlighted ? highlightColor : Color("AppInk").opacity(0.4)
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
    VStack(spacing: 0) {
        BudgetBreakdownRow(
            category: Category(name: "Dining out", monthlyLimit: 800_000, colorToken: "orange"),
            spent: 950_000,
            status: .over
        )
        Divider()
        BudgetBreakdownRow(
            category: Category(name: "Groceries", monthlyLimit: 1_500_000, colorToken: "green"),
            spent: 1_500_000,
            status: .atLimit
        )
        Divider()
        BudgetBreakdownRow(
            category: Category(name: "Transport", monthlyLimit: 400_000, colorToken: "blue"),
            spent: 250_000,
            status: .under
        )
        Divider()
        BudgetBreakdownRow(
            category: Category(name: "Home", monthlyLimit: 300_000, colorToken: "yellow"),
            spent: 0,
            status: .under
        )
        Divider()
        BudgetBreakdownRow(
            category: Category(name: "Fun", monthlyLimit: nil, colorToken: "pink"),
            spent: 150_000,
            status: .noLimit
        )
    }
    .background(Color("AppCard"))
}
