//
//  TransactionDayGroupSection.swift
//  SpendWise
//

import SwiftUI

/// One day's section of the Transactions screen's list: a header (`TODAY`,
/// `YESTERDAY`, or e.g. `WED 24 AUG`, with a `· UPCOMING` suffix and accent
/// tint for future-dated days) showing that day's subtotal, followed by
/// every transaction dated that day.
struct TransactionDayGroupSection: View {

    // MARK: - Properties

    let group: TransactionDayGroup

    // MARK: - Body

    var body: some View {
        Section {
            ForEach(group.transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
        } header: {
            HStack {
                Text(DateLabelFormatter.dayHeader(for: group.date))
                    .foregroundStyle(isUpcoming ? Color.accentColor : Color.secondary)

                Spacer()

                Text(RupiahFormatter.string(from: group.subtotal))
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
        }
    }

    // MARK: - Derived

    /// Whether `group.date` falls after today, matching the condition
    /// `DateLabelFormatter.dayHeader(for:)` uses internally to append the
    /// `· UPCOMING` suffix — recomputed here (rather than parsed back out of
    /// the formatted string) so the accent tint stays in sync with that
    /// logic by construction.
    private var isUpcoming: Bool {
        Calendar.current.startOfDay(for: group.date) > Calendar.current.startOfDay(for: .now)
    }
}

// MARK: - Previews

#Preview {
    let groceries = Category(name: "Groceries", colorToken: "green")
    let today = TransactionDayGroup(date: Calendar.current.startOfDay(for: .now), transactions: [
        Transaction(amount: 450_000, date: .now, note: "Weekly groceries", category: groceries),
        Transaction(amount: 45_000, date: .now, note: "", category: nil)
    ])

    return List {
        TransactionDayGroupSection(group: today)
    }
}
