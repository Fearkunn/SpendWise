//
//  TransactionDayGroupSection.swift
//  SpendWise
//

import SwiftUI

/// One day's section of the Transactions screen's list: a header (`TODAY`,
/// `YESTERDAY`, or e.g. `WED 24 AUG`, with a `· UPCOMING` suffix for
/// future-dated days, and an accent tint for both today's and any upcoming
/// group) showing that day's subtotal, followed by every transaction dated
/// that day.
///
/// Each row is tappable (#13): tapping opens the shared expense sheet in
/// edit mode, pre-filled with that transaction's data. Each row also
/// supports swipe-to-delete (#14) via the native `.swipeActions` modifier —
/// a left swipe reveals a destructive "Delete" action that removes the
/// transaction immediately, with no confirmation dialog (undo, not
/// confirmation, is how a mistaken delete gets corrected). `TransactionRow`
/// itself stays presentation-only — the tap gesture, swipe action, and
/// their callbacks live here instead, matching the project's convention of
/// keeping row components free of behavior.
struct TransactionDayGroupSection: View {

    // MARK: - Properties

    let group: TransactionDayGroup
    let onSelect: (Transaction) -> Void
    let onDelete: (Transaction) -> Void

    // MARK: - Body

    var body: some View {
        Section {
            ForEach(group.transactions) { transaction in
                TransactionRow(transaction: transaction)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(transaction) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(transaction)
                        } label: {
                            Text("Delete")
                        }
                    }
            }
        } header: {
            HStack {
                Text(DateLabelFormatter.dayHeader(for: group.date))
                    .font(.caption.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(isAccented ? Color("AppAccent") : Color.secondary)

                Spacer()

                Text(RupiahFormatter.string(from: group.subtotal))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Derived

    /// Whether this group's header is tinted with the accent color: today's
    /// group, or an upcoming (future-dated) group — matching the mockup,
    /// where both stand out from the plain "earlier day" header color.
    private var isAccented: Bool {
        let startOfGroupDate = Calendar.current.startOfDay(for: group.date)
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return startOfGroupDate >= startOfToday
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
        TransactionDayGroupSection(group: today, onSelect: { _ in }, onDelete: { _ in })
    }
}
