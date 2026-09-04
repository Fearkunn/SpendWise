//
//  NoExpensesEmptyStateView.swift
//  SpendWise
//

import SwiftUI

/// The Transactions screen's first-launch empty state: shown when no
/// transaction exists anywhere, in any month.
///
/// The "Log an expense" call to action matches the source design and, as of
/// #13, opens the add-expense sheet — the same `onAddTx` handler the
/// mockup shares with the header's "+ Expense" button.
struct NoExpensesEmptyStateView: View {

    // MARK: - Properties

    let onLogExpense: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No expenses yet")
                    .font(.title3.weight(.semibold))

                Text("Log the first one and this list fills in, newest at the top, grouped by day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Log an expense", action: onLogExpense)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview {
    NoExpensesEmptyStateView(onLogExpense: {})
}
