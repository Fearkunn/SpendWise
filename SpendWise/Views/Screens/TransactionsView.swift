//
//  TransactionsView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The Transactions tab's real screen (#12): a month stepper header with
/// the month's total spend, and a day-grouped, newest-first list of that
/// month's expenses.
///
/// Read-only for now — adding, editing, and deleting expenses land in #13
/// and #14. Per CLAUDE.md, this view reads data via `@Query` directly and
/// only reaches for `TransactionViewModel` for the one piece of read state
/// it doesn't own itself: the month total, via the already-tested
/// `monthTotal(in:)` aggregation (#8) — every other computation here
/// (day-grouping, list state, the jump-back target) is done in Swift over
/// the `@Query` results, since a SwiftData `@Query` predicate can't cleanly
/// re-bind to the changing `selectedMonth` binding.
struct TransactionsView: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @Binding var selectedMonth: MonthKey

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            switch listState {
            case .noExpensesAtAll:
                NoExpensesEmptyStateView()
            case .monthEmpty(let hasEarlierMonthWithData):
                MonthEmptyStateView(
                    selectedMonth: selectedMonth,
                    currentMonth: .current,
                    earlierMonth: hasEarlierMonthWithData ? nearestEarlierMonthWithData : nil,
                    onBackToCurrentMonth: { selectedMonth = .current },
                    onJumpToEarlierMonth: { selectedMonth = $0 }
                )
            case .populated:
                populatedList
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Button {
                    selectedMonth = selectedMonth.previous()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                }

                Text(selectedMonth.labelUppercased)
                    .font(.caption2.weight(.medium))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)

                Button {
                    selectedMonth = selectedMonth.next()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.plain)

            Text(RupiahFormatter.string(from: monthTotal))
                .font(.largeTitle.bold().monospacedDigit())

            Text(monthSpendCaption)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Populated List

    private var populatedList: some View {
        List {
            Section {
                HStack {
                    Text("Expenses")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(countLabelText)
                        .font(.caption2)
                        .tracking(0.5)
                        .foregroundStyle(.tertiary)
                }
                .listRowSeparator(.hidden)
            }

            ForEach(dayGroups) { group in
                TransactionDayGroupSection(group: group)
            }

            if let nearestEarlierMonthWithData {
                HStack {
                    Spacer()
                    JumpToPreviousMonthPill(targetMonth: nearestEarlierMonthWithData) {
                        selectedMonth = nearestEarlierMonthWithData
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Derived State

    private var transactionViewModel: TransactionViewModel {
        TransactionViewModel(modelContext: modelContext)
    }

    /// The selected month's total spend across every category, including
    /// uncategorized expenses — computed via `TransactionViewModel`'s
    /// already-tested aggregation rather than re-summed here.
    ///
    /// A fetch failure falls back to `0` rather than surfacing an alert;
    /// `TransactionViewModel` already logs the underlying error, and this is
    /// a read-only display value with no user action to retry.
    private var monthTotal: Int {
        (try? transactionViewModel.monthTotal(in: selectedMonth.startOfMonth)) ?? 0
    }

    private var monthTransactions: [Transaction] {
        allTransactions.filter { MonthKey(date: $0.date) == selectedMonth }
    }

    private var dayGroups: [TransactionDayGroup] {
        TransactionDayGroup.makeGroups(from: allTransactions, in: selectedMonth)
    }

    private var nearestEarlierMonthWithData: MonthKey? {
        TransactionMonthLookup.nearestEarlierMonthWithData(before: selectedMonth, in: allTransactions)
    }

    private var listState: TransactionListState {
        .determine(
            totalTransactionCount: allTransactions.count,
            monthTransactionCount: monthTransactions.count,
            hasEarlierMonthWithData: nearestEarlierMonthWithData != nil
        )
    }

    // MARK: - Derived Text

    private var monthSpendCaption: String {
        if selectedMonth == .current {
            "spent this month, all categories"
        } else {
            "spent in \(selectedMonth.label), all categories"
        }
    }

    private var countLabelText: String {
        let count = monthTransactions.count
        return count == 1 ? "1 EXPENSE" : "\(count) EXPENSES"
    }
}

// MARK: - Previews

#Preview("Populated") {
    @Previewable @State var selectedMonth: MonthKey = .current
    TransactionsView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.richContainer())
}

#Preview("Month empty, data elsewhere") {
    @Previewable @State var selectedMonth: MonthKey = MonthKey.current.next()
    TransactionsView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.sparseContainer())
}

#Preview("No expenses at all") {
    @Previewable @State var selectedMonth: MonthKey = .current
    TransactionsView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.firstLaunchContainer())
}
