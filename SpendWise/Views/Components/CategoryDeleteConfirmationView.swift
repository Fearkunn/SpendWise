//
//  CategoryDeleteConfirmationView.swift
//  SpendWise
//

import SwiftUI

/// The category delete confirmation dialog (#17): a centered modal overlay
/// (not a bottom sheet), reachable from both the Categories row's swipe
/// "Delete" and `CategorySheetView`'s own "Delete category" button.
///
/// Unlike expense deletion — unconfirmed and undo-based (#14) — a category
/// delete always confirms, since it can silently re-home many transactions
/// to Uncategorized. Presentation-only: `CategoriesView` owns the pending
/// delete's state (which category, its all-time expense count, and any
/// delete-failure message) and supplies it here, along with what tapping
/// each action does.
///
/// Matches the design mockup's `confirmOpen` overlay
/// (`Design/SpendWise.dc.html`) exactly: a dimmed backdrop that also acts as
/// a "Keep it" tap target, a `#FFFDFA` card (`AppModalBackground`), an
/// inline error slot that only appears once a delete attempt has failed,
/// and the destructive `oklch(.53 .15 28)` CTA fill — the same hue as
/// `BudgetOver`, reused here rather than introducing a near-duplicate
/// token.
struct CategoryDeleteConfirmationView: View {

    // MARK: - Properties

    let categoryName: String
    let expenseCount: Int
    let errorMessage: String?
    let onKeep: () -> Void
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Color("AppInk")
                .opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onKeep)

            card
                .padding(28)
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(CategoryDeleteConfirmationCopy.title(categoryName: categoryName))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("AppInk"))

            Text(CategoryDeleteConfirmationCopy.body(expenseCount: expenseCount))
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(Color("AppInk").opacity(0.55))
                .padding(.top, 8)

            if let errorMessage {
                errorBanner(errorMessage)
                    .padding(.top, 12)
            }

            actionButtons
                .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .background(Color("AppModalBackground"), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color("AppInk").opacity(0.3), radius: 25, y: 10)
    }

    // MARK: - Error Banner

    /// The inline error slot for a failed delete attempt. Deliberately kept
    /// simpler than `CategorySheetView`'s own error banner (no "!" glyph) to
    /// match the mockup's `confirmError` markup exactly — it's a plain
    /// tinted box, reusing `BudgetOver` for the tint rather than the
    /// mockup's literal `#FAEDE8`/`oklch(.42 .12 28)` values, since that's
    /// the same red hue this codebase already standardizes on for
    /// error/over-budget treatment.
    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12.5))
            .lineSpacing(3)
            .foregroundStyle(Color("BudgetOver"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color("BudgetOver").opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color("BudgetOver").opacity(0.2))
            )
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 9) {
            Button(action: onKeep) {
                Text(CategoryDeleteConfirmationCopy.keepActionTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("AppInk"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("AppCard"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.14))
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Text(CategoryDeleteConfirmationCopy.deleteActionTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("BudgetOver"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews

#Preview("No expenses use it") {
    CategoryDeleteConfirmationView(
        categoryName: "Home",
        expenseCount: 0,
        errorMessage: nil,
        onKeep: {},
        onDelete: {}
    )
}

#Preview("Many expenses, retrying after a failure") {
    CategoryDeleteConfirmationView(
        categoryName: "Groceries",
        expenseCount: 12,
        errorMessage: "Couldn't delete — nothing has changed. Try again.",
        onKeep: {},
        onDelete: {}
    )
}
