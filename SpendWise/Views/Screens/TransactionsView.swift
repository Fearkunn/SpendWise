//
//  TransactionsView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The Transactions tab's real screen (#12, #13): a month stepper header
/// with the month's total spend and an "+ Expense" button, and a
/// day-grouped, newest-first list of that month's expenses.
///
/// Adding, editing, and deleting expenses (#13) works by presenting
/// `ExpenseSheetView` in add or edit mode; deletion beyond the sheet's own
/// "Delete this expense" button (e.g. swipe-to-delete, undo) is #14's scope.
/// Per CLAUDE.md, this view reads data via `@Query` directly and only
/// reaches for `TransactionViewModel` for the one piece of read state it
/// doesn't own itself: the month total, via the already-tested
/// `monthTotal(in:)` aggregation (#8) — every other computation here
/// (day-grouping, list state, the jump-back target) is done in Swift over
/// the `@Query` results, since a SwiftData `@Query` predicate can't cleanly
/// re-bind to the changing `selectedMonth` binding.
struct TransactionsView: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @Binding var selectedMonth: MonthKey

    @State private var activeSheet: ExpenseSheetView.Mode?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            switch listState {
            case .noExpensesAtAll:
                NoExpensesEmptyStateView(onLogExpense: { activeSheet = .add })
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
        .sheet(item: $activeSheet) { mode in
            ExpenseSheetView(mode: mode, selectedMonth: $selectedMonth)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
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

            addExpenseButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var addExpenseButton: some View {
        Button {
            activeSheet = .add
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                Text("Expense")
                    .font(.footnote.weight(.semibold))
            }
            .padding(.leading, 13)
            .padding(.trailing, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.accentColor))
            .foregroundStyle(Color(.systemBackground))
        }
        .buttonStyle(.plain)
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
                TransactionDayGroupSection(group: group, onSelect: { activeSheet = .edit($0) })
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
