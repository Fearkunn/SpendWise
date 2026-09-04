//
//  MonthEmptyStateView.swift
//  SpendWise
//

import SwiftUI

/// The Transactions screen's "nothing logged in the selected month" empty
/// state: shown when transactions exist somewhere, just not within the
/// currently selected month.
///
/// Body copy differs depending on whether an earlier month has data to jump
/// back to (`earlierMonth`) — when it doesn't, the copy deliberately avoids
/// implying earlier months are still there to find.
struct MonthEmptyStateView: View {

    // MARK: - Properties

    let selectedMonth: MonthKey
    let currentMonth: MonthKey
    let earlierMonth: MonthKey?
    let onBackToCurrentMonth: () -> Void
    let onJumpToEarlierMonth: (MonthKey) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("Nothing logged in \(selectedMonth.label)")
                    .font(.title3.weight(.semibold))

                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button("Back to \(currentMonth.shortLabel)", action: onBackToCurrentMonth)
                    .buttonStyle(.bordered)

                if let earlierMonth {
                    JumpToPreviousMonthPill(targetMonth: earlierMonth) {
                        onJumpToEarlierMonth(earlierMonth)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Derived Text

    private var bodyText: String {
        if earlierMonth != nil {
            return "Earlier months are still here — step back, or add an expense dated in this one."
        } else {
            return "Nothing here yet — add an expense dated in this month, or jump back to \(currentMonth.label)."
        }
    }
}

// MARK: - Previews

#Preview("With earlier data") {
    MonthEmptyStateView(
        selectedMonth: MonthKey(year: 2026, month: 9),
        currentMonth: MonthKey(year: 2026, month: 9),
        earlierMonth: MonthKey(year: 2026, month: 7),
        onBackToCurrentMonth: {},
        onJumpToEarlierMonth: { _ in }
    )
}

#Preview("No earlier data") {
    MonthEmptyStateView(
        selectedMonth: MonthKey(year: 2020, month: 1),
        currentMonth: MonthKey(year: 2026, month: 9),
        earlierMonth: nil,
        onBackToCurrentMonth: {},
        onJumpToEarlierMonth: { _ in }
    )
}
