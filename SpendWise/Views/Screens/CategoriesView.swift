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
/// This is explicitly a read-only-of-destination screen, mirroring #12's
/// precedent for `TransactionsView`: the add/edit sheet and the delete
/// confirmation dialog are both out of scope for this issue (a category
/// delete needs confirmation rather than the Transactions screen's
/// undo-on-swipe pattern, since it can silently re-home many transactions
/// to Uncategorized). `onAddCategory`, `onSelectCategory`, and
/// `onDeleteCategory` are present so the row/button affordances the issue
/// asks for (tap to edit, swipe to reveal Delete, "+ New") are all wired
/// up and ready, but default to doing nothing until a future issue builds
/// those destinations and passes real handlers in.
///
/// Per CLAUDE.md, this view reads categories via `@Query` directly and
/// only reaches for `CategoryViewModel`/`TransactionViewModel` for the
/// pieces of read state it doesn't own itself: each row's spend for the
/// selected month (`TransactionViewModel.spent(in:categoryID:)`, #8) and
/// the resulting `BudgetStatus` (`CategoryViewModel.budgetStatus(limit:spent:)`,
/// #9) — this view is the one place responsible for combining the two,
/// since neither ViewModel may depend on the other.
struct CategoriesView: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @Binding var selectedMonth: MonthKey

    /// Handles the "+ New" button and the empty state's "Add a category"
    /// button. No-op by default — the add/edit sheet is out of scope for
    /// #15; see this type's doc comment.
    var onAddCategory: () -> Void = {}

    /// Handles tapping a row to edit it. No-op by default — see
    /// `onAddCategory`'s doc comment; the same sheet would present both.
    var onSelectCategory: (Category) -> Void = { _ in }

    /// Handles tapping "Delete" after swiping a row. No-op by default —
    /// the confirmation dialog that actually calls
    /// `CategoryViewModel.delete(_:)` is out of scope for #15.
    var onDeleteCategory: (Category) -> Void = { _ in }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            if categories.isEmpty {
                EveryCategoryGoneEmptyStateView(onAddCategory: onAddCategory)
            } else {
                populatedList
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
        Button(action: onAddCategory) {
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
                    .onTapGesture { onSelectCategory(category) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDeleteCategory(category)
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
