//
//  BudgetMonthEmptyStateView.swift
//  SpendWise
//

import SwiftUI

/// The Budget screen's (#18) "nothing spent this month" empty state.
///
/// Distinct from the Transactions screen's `MonthEmptyStateView`: different
/// copy ("Nothing spent in [Month]" vs. "Nothing logged in [Month]"), a
/// single "Back to [Month]" action with no jump-to-earlier-month option, and
/// reassuring copy that limits are unaffected by browsing an empty month —
/// matching the source design mockup exactly rather than reusing the
/// Transactions screen's component.
struct BudgetMonthEmptyStateView: View {

    // MARK: - Properties

    let selectedMonth: MonthKey
    let currentMonth: MonthKey
    let onBackToCurrentMonth: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .strokeBorder(Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: 54, height: 54)

            VStack(spacing: 7) {
                Text("Nothing spent in \(selectedMonth.label)")
                    .font(.system(size: 16.5, weight: .semibold))
                    .foregroundStyle(Color("AppInk"))

                Text("Your limits still stand — there's just nothing to measure against them yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("AppInk").opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button("Back to \(currentMonth.shortLabel)", action: onBackToCurrentMonth)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color("AppInk"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color("AppCard"))
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.13)))
                )
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 40)
        .background(Color("AppCard"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.08)))
        .padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Previews

#Preview {
    BudgetMonthEmptyStateView(
        selectedMonth: MonthKey(year: 2026, month: 7),
        currentMonth: .current,
        onBackToCurrentMonth: {}
    )
    .padding()
    .background(Color("AppSurface"))
}
