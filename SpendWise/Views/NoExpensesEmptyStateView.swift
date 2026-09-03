//
//  NoExpensesEmptyStateView.swift
//  SpendWise
//

import SwiftUI

/// The Transactions screen's first-launch empty state: shown when no
/// transaction exists anywhere, in any month.
///
/// The "Log an expense" call to action matches the source design, but #12
/// is explicitly read-only — adding an expense is #13's scope. The button
/// is intentionally disabled here rather than wired to open anything or
/// silently doing nothing when tapped.
struct NoExpensesEmptyStateView: View {

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No expenses yet")
                    .font(.title3.weight(.semibold))

                Text("Log your first expense to get started — it'll show up here, newest first and grouped by day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Log an expense") {}
                .buttonStyle(.borderedProminent)
                .disabled(true)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview {
    NoExpensesEmptyStateView()
}
