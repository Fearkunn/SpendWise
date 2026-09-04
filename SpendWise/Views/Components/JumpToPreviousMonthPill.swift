//
//  JumpToPreviousMonthPill.swift
//  SpendWise
//

import SwiftUI

/// A small pill button — e.g. `‹ July 2026` — that jumps the shared
/// selected month back to the nearest earlier month containing data.
///
/// Shared between two spots on the Transactions screen: the bottom of the
/// populated day-grouped list, and the month-empty state (when an earlier
/// month with data exists) — both driven by the same
/// `TransactionMonthLookup.nearestEarlierMonthWithData(before:in:)` result.
struct JumpToPreviousMonthPill: View {

    // MARK: - Properties

    let targetMonth: MonthKey
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                Text(targetMonth.label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    JumpToPreviousMonthPill(targetMonth: MonthKey(year: 2026, month: 7), action: {})
        .padding()
}
