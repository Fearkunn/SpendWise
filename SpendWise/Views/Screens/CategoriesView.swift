//
//  CategoriesView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The Categories tab's real screen (#15): every category with its spend
/// against its limit for the selected month, plus a header count/limit
/// summary and a month stepper.
///
/// Adding and editing a category (#16) works by presenting
/// `CategorySheetView` in add or edit mode via an internal `activeSheet`,
/// mirroring `TransactionsView`'s identical `ExpenseSheetView` (#13)
/// wiring exactly.
///
/// Deleting a category (#17) always confirms first — unlike expense
/// deletion, which is unconfirmed and undo-based (#14), since a category
/// delete can silently re-home many transactions to Uncategorized. This
/// view owns that confirmation as `deleteRequest`, converging both entry
/// points on it: row swipe-to-delete calls `beginDelete(_:)` directly, and
/// `CategorySheetView`'s own "Delete category" button reaches it via
/// `onRequestDelete`, matching the mockup's `askDeleteCat` (closing the
/// sheet and opening the confirmation dialog in the same step, never
/// stacking the two). `confirmDelete()` is what actually calls
/// `CategoryViewModel.delete(_:)`; a failure keeps `deleteRequest` set
/// with an error message instead of dismissing, so
/// `CategoryDeleteConfirmationView` can show it inline and the user can
/// retry.
///
/// Per CLAUDE.md, this view reads categories via `@Query` directly and
/// only reaches for `CategoryViewModel`/`TransactionViewModel` for the
/// pieces of read state it doesn't own itself: each row's spend for the
/// selected month (`TransactionViewModel.spent(in:categoryID:)`, #8), the
/// resulting `BudgetStatus` (`CategoryViewModel.budgetStatus(limit:spent:)`,
/// #9), and — for the delete confirmation's body copy — a category's
/// all-time expense count (`TransactionViewModel.count(categoryID:)`, #17).
/// This view is the one place responsible for combining these, since
/// neither ViewModel may depend on the other.
struct CategoriesView: View {

    // MARK: - Delete Request

    /// The pending category delete's view-wiring state: which category, its
    /// all-time expense count (for `CategoryDeleteConfirmationCopy.body(expenseCount:)`),
    /// and any delete-failure message. Kept private to this view, mirroring
    /// `RootView.PendingExpenseDeletion`'s identical precedent, rather than
    /// promoted to a Domain type — only the pure copy derivation belongs
    /// there.
    private struct DeleteRequest: Identifiable {
        let category: Category
        let expenseCount: Int
        var errorMessage: String?

        var id: PersistentIdentifier { category.persistentModelID }
    }

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @Binding var selectedMonth: MonthKey

    @State private var activeSheet: CategorySheetView.Mode?
    @State private var deleteRequest: DeleteRequest?

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header

                if categories.isEmpty {
                    EveryCategoryGoneEmptyStateView(onAddCategory: { activeSheet = .add })
                } else {
                    populatedList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .sheet(item: $activeSheet) { mode in
                CategorySheetView(mode: mode, onRequestDelete: beginDelete)
            }

            if let deleteRequest {
                CategoryDeleteConfirmationView(
                    categoryName: deleteRequest.category.name,
                    expenseCount: deleteRequest.expenseCount,
                    errorMessage: deleteRequest.errorMessage,
                    onKeep: { self.deleteRequest = nil },
                    onDelete: confirmDelete
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Categories")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color("AppInk"))

                Text(subtitleText)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color("AppInk").opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            newCategoryButton
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var newCategoryButton: some View {
        Button { activeSheet = .add } label: {
            HStack(spacing: 6) {
                Text("+")
                    .font(.system(size: 17))
                Text("New")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color("AppInk"))
            .padding(.leading, 12)
            .padding(.trailing, 15)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color("AppCard"))
                    .overlay(Capsule().strokeBorder(Color.primary.opacity(0.13)))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Populated List

    private var populatedList: some View {
        List {
            Section {
                ForEach(categories) { category in
                    CategoryRow(
                        category: category,
                        spent: spent(for: category),
                        status: status(for: category)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { activeSheet = .edit(category) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            beginDelete(category)
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            } header: {
                monthStepper
            } footer: {
                Text("Deleting a category never deletes its expenses — they move to Uncategorized.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color("AppInk").opacity(0.4))
                    .padding(.top, 4)
            }
        }
        .listStyle(.plain)
    }

    private var monthStepper: some View {
        HStack(spacing: 5) {
            monthStepButton(systemName: "chevron.left") {
                selectedMonth = selectedMonth.previous()
            }

            Text(monthNoteText)
                .font(.system(size: 9.5, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Color("AppInk").opacity(0.42))

            monthStepButton(systemName: "chevron.right") {
                selectedMonth = selectedMonth.next()
            }
        }
        .buttonStyle(.plain)
        .textCase(nil)
    }

    private func monthStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color("AppInk"))
                .frame(width: 22, height: 22)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.05)))
        }
    }

    // MARK: - Delete

    /// Starts the delete confirmation flow for `category`, from either
    /// entry point (row swipe or `CategorySheetView`'s delete button).
    ///
    /// A failed count fetch falls back to `0` rather than blocking the
    /// dialog from opening — matching `spent(for:)`'s identical
    /// read-only-display fallback precedent below. The only consequence is
    /// the body copy understating the affected count; the actual delete,
    /// and the model's `.nullify` rule, are unaffected by what this number
    /// says.
    private func beginDelete(_ category: Category) {
        let count = (try? transactionViewModel.count(categoryID: category.persistentModelID)) ?? 0
        deleteRequest = DeleteRequest(category: category, expenseCount: count)
    }

    /// Confirms the pending delete: calls `CategoryViewModel.delete(_:)`
    /// and, on success, dismisses the dialog. On failure, `deleteRequest`
    /// stays set with the error message so `CategoryDeleteConfirmationView`
    /// can show it inline and the user can tap "Delete category" again to
    /// retry.
    private func confirmDelete() {
        guard let deleteRequest else { return }

        do {
            try categoryViewModel.delete(deleteRequest.category)
            self.deleteRequest = nil
        } catch {
            self.deleteRequest?.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Derived State

    private var transactionViewModel: TransactionViewModel {
        TransactionViewModel(modelContext: modelContext)
    }

    private var categoryViewModel: CategoryViewModel {
        CategoryViewModel(modelContext: modelContext)
    }

    /// A category's spend for the selected month, via `TransactionViewModel`'s
    /// already-tested aggregation. A fetch failure falls back to `0` rather
    /// than surfacing an alert, matching `TransactionsView`'s precedent —
    /// this is a read-only display value with no user action to retry.
    private func spent(for category: Category) -> Int {
        (try? transactionViewModel.spent(in: selectedMonth.startOfMonth, categoryID: category.persistentModelID)) ?? 0
    }

    private func status(for category: Category) -> BudgetStatus {
        categoryViewModel.budgetStatus(limit: category.monthlyLimit, spent: spent(for: category))
    }

    private var totalMonthlyLimit: Int {
        categories.reduce(0) { $0 + ($1.monthlyLimit ?? 0) }
    }

    // MARK: - Derived Text

    private var subtitleText: String {
        CategoriesSummary.subtitle(count: categories.count, totalMonthlyLimit: totalMonthlyLimit)
    }

    private var monthNoteText: String {
        "SPEND SHOWN FOR " + selectedMonth.labelUppercased
    }
}

// MARK: - Previews

#Preview("Populated") {
    @Previewable @State var selectedMonth: MonthKey = .current
    CategoriesView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.richContainer())
}

#Preview("Every category is gone") {
    @Previewable @State var selectedMonth: MonthKey = .current
    CategoriesView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.noCategoriesContainer())
}
