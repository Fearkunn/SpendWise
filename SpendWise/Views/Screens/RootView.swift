//
//  RootView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The app's shell: a three-tab container (Transactions, Budget,
/// Categories) with a custom floating pill tab bar in place of the
/// standard iOS tab bar, and the single selected month shared across all
/// three tabs.
///
/// The selected month is transient UI state, not entity data, so per
/// CLAUDE.md it does not live on `TransactionViewModel` or
/// `CategoryViewModel` — it's held here as `@State` and threaded down to
/// each tab as a `Binding<MonthKey>`. Paging the month from any tab updates
/// this one source of truth, so every tab stays in sync.
///
/// Each tab's actual content is out of scope for this shell (see #12, #15,
/// #18) and shown here only as `TabPlaceholderView`.
///
/// The swipe-to-delete undo/retry toast (#14) also lives here rather than
/// on `TransactionsView`: the mockup keeps the toast visible across tab
/// switches, so its state has to live at least as high as `selectedTab`
/// itself. `pendingExpenseDeletion` holds whichever of "undo this delete"
/// or "retry this delete" is currently pending; `TransactionsView` only
/// gets a callback to kick that flow off.
struct RootView: View {

    // MARK: - Pending Expense Deletion

    /// The view-wiring half of the undo/retry toast: which record to
    /// restore, or which transaction to retry deleting. `ExpenseDeleteToast`
    /// itself (message/action label/variant) is the pure, testable part of
    /// this and lives in `Domain/Transaction/`; this enum only carries the
    /// extra state needed to actually act on the toast, so it stays private
    /// to this view rather than being promoted to a Domain type.
    private enum PendingExpenseDeletion {
        case undo(toast: ExpenseDeleteToast, snapshot: DeletedExpenseSnapshot)
        case retry(toast: ExpenseDeleteToast, transaction: Transaction)

        var toast: ExpenseDeleteToast {
            switch self {
            case .undo(let toast, _): toast
            case .retry(let toast, _): toast
            }
        }
    }

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: AppTab = .transactions
    @State private var selectedMonth: MonthKey = .current
    @State private var pendingExpenseDeletion: PendingExpenseDeletion?

    // MARK: - Body

    var body: some View {
        // The toast is a genuine, unconditional `VStack` sibling stacked
        // *above* the tab content, rather than an `.overlay` or
        // `.safeAreaInset` layered onto the `ZStack`/`TabView` below — both
        // of those were tried and both let the toast overlap
        // `TransactionsView`'s own header instead of pushing it down,
        // because `TabView` doesn't reliably propagate an externally
        // injected safe-area inset into whichever tab is currently
        // selected. Plain top-to-bottom `VStack` flow has no such
        // dependency: the toast simply occupies real height, and everything
        // stacked after it is laid out lower as an ordinary consequence of
        // that, regardless of how `TabView` manages safe areas internally.
        //
        // Neither the toast nor this `VStack` calls `.ignoresSafeArea()`,
        // so — matching every other plain SwiftUI view — the toast renders
        // clear of the status bar/notch by default; no manual top-safe-area
        // math is needed. When the toast is absent, the `if let` below
        // contributes zero height, so the `ZStack` becomes this `VStack`'s
        // only child and sits exactly where it always has, letting
        // `Color("AppSurface").ignoresSafeArea()` bleed to the true top and
        // bottom screen edges exactly as before.
        VStack(spacing: 0) {
            if let pendingExpenseDeletion {
                ExpenseDeleteToastView(
                    toast: pendingExpenseDeletion.toast,
                    onAction: handleToastAction,
                    onDismiss: { self.pendingExpenseDeletion = nil }
                )
                .padding(.top, 8)
            }

            ZStack(alignment: .bottom) {
                Color("AppSurface")
                    .ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    ForEach(AppTab.allCases) { tab in
                        tabContent(for: tab)
                            .tag(tab)
                    }
                }
                .toolbar(.hidden, for: .tabBar)

                floatingTabBar
            }
        }
    }

    // MARK: - Subviews

    /// Each tab's real content, where it exists — currently just
    /// Transactions (#12). Budget (#18) and Categories (#15) still show
    /// `TabPlaceholderView` until their own screens land.
    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .transactions:
            TransactionsView(selectedMonth: $selectedMonth, onDeleteExpense: attemptDelete)
        case .budget, .categories:
            TabPlaceholderView(tab: tab, selectedMonth: $selectedMonth)
        }
    }

    /// The pill tab bar, anchored to the bottom with a soft upward
    /// gradient behind it so content scrolling underneath fades out rather
    /// than being hard-clipped by the pill's backdrop.
    private var floatingTabBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color("AppSurface").opacity(0), Color("AppSurface")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)

            AppTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
                .background(Color("AppSurface"))
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Expense Deletion

    private var transactionViewModel: TransactionViewModel {
        TransactionViewModel(modelContext: modelContext)
    }

    /// Attempts to delete `transaction`, capturing its field values into a
    /// `DeletedExpenseSnapshot` *before* the delete call — the object itself
    /// won't be readable afterward — and shows the resulting undo/error
    /// toast. A second delete attempted while a toast is already showing
    /// simply replaces it, matching the mockup's own single-level-undo
    /// limitation.
    private func attemptDelete(_ transaction: Transaction) {
        let snapshot = DeletedExpenseSnapshot(transaction: transaction)

        do {
            try transactionViewModel.delete(transaction)
            pendingExpenseDeletion = .undo(toast: .make(outcome: .success), snapshot: snapshot)
        } catch {
            pendingExpenseDeletion = .retry(toast: .make(outcome: .failure), transaction: transaction)
        }
    }

    /// The toast's single action: "Undo" for a successful delete, "Retry"
    /// for a failed one.
    private func handleToastAction() {
        guard let pendingExpenseDeletion else { return }

        switch pendingExpenseDeletion {
        case .undo(_, let snapshot):
            undoDelete(snapshot)
        case .retry(_, let transaction):
            self.pendingExpenseDeletion = nil
            attemptDelete(transaction)
        }
    }

    /// Recreates the deleted transaction from its captured field values and
    /// jumps the shared selected month to follow it — mirroring
    /// `ExpenseSheetView.save()`'s identical jump-to-saved-record's-month
    /// pattern from #13, so the restored row is actually visible rather
    /// than appearing to have "failed" to come back.
    private func undoDelete(_ snapshot: DeletedExpenseSnapshot) {
        // A failure here is rare — the same validation that allowed the
        // original save should still pass on identical field values — and
        // `TransactionViewModel.add` already logs it if it happens. The
        // mockup doesn't model an "undo failed" state, so there's nothing
        // further to surface; the toast is simply cleared either way.
        if let restored = try? transactionViewModel.add(
            amountText: String(snapshot.amount),
            date: snapshot.date,
            note: snapshot.note,
            category: snapshot.category
        ) {
            selectedMonth = MonthKey(date: restored.date)
        }

        pendingExpenseDeletion = nil
    }
}

// MARK: - Previews

#Preview {
    RootView()
}
