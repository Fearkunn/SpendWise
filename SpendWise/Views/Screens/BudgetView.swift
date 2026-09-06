//
//  BudgetView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The Budget tab's real screen (#18): a month stepper card, a summary card
/// with a donut ring showing categorized spend against total limits, and a
/// by-category breakdown.
///
/// This is the reference implementation of CLAUDE.md's cross-entity
/// ownership rule: it's the one place in the app that combines
/// `TransactionViewModel` (month/category spend aggregation) with
/// `CategoryViewModel.budgetStatus(limit:spent:)` (status classification).
/// Neither ViewModel references the other — every aggregate this view needs
/// (`monthTotal(in:)`, `spent(in:categoryID:)`, `uncategorizedTotal(in:)`)
/// already exists on `TransactionViewModel`, and every `BudgetStatus` shown
/// here, whether for the overall ring or a single row, comes from the same
/// `CategoryViewModel.budgetStatus(limit:spent:)` call, fed the spend this
/// view already computed.
///
/// Per the issue's accepted behavior, `totalLimit` sums every *current*
/// category's `monthlyLimit` regardless of which month is being viewed —
/// limits aren't versioned per month, so browsing a past month compares that
/// month's spend against today's limits.
struct BudgetView: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    @Binding var selectedMonth: MonthKey

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            monthStepperCard

            ScrollView {
                if monthTotal == 0 {
                    BudgetMonthEmptyStateView(
                        selectedMonth: selectedMonth,
                        currentMonth: .current,
                        onBackToCurrentMonth: { selectedMonth = .current }
                    )
                } else {
                    monthContent
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("AppSurface"))
    }

    // MARK: - Month Stepper Card

    private var monthStepperCard: some View {
        HStack {
            monthStepButton(systemName: "chevron.left") {
                selectedMonth = selectedMonth.previous()
            }

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text(selectedMonth.label)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(Color("AppInk"))

                Text(selectedMonth.relativeLabel)
                    .font(.system(size: 9, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Color("AppInk").opacity(0.4))
            }

            Spacer(minLength: 0)

            monthStepButton(systemName: "chevron.right") {
                selectedMonth = selectedMonth.next()
            }
        }
        .padding(7)
        .background(Color("AppCard"))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(Color.primary.opacity(0.08)))
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private func monthStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color("AppInk"))
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 11).fill(Color.primary.opacity(0.045)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Month Content

    private var monthContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            summaryCard

            sectionHeader

            breakdownCard

            if uncategorizedTotal > 0 {
                uncategorizedBlock
            }

            if categories.isEmpty {
                noCategoriesBlock
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(alignment: .center, spacing: 20) {
            BudgetRingView(
                fraction: ringSummary.ringFraction,
                ringColor: ringColor,
                percentTextColor: ringTextColor,
                percentText: ringSummary.percentText
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(RupiahFormatter.string(from: totalSpent))
                    .font(.system(size: 25, weight: .semibold, design: .default))
                    .foregroundStyle(Color("AppInk"))

                Text("of \(RupiahFormatter.string(from: totalLimit)) budgeted")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color("AppInk").opacity(0.5))

                if uncategorizedTotal > 0 {
                    Text("+ \(RupiahFormatter.string(from: uncategorizedTotal)) UNCATEGORIZED")
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(0.9)
                        .foregroundStyle(Color("AppInk").opacity(0.36))
                        .padding(.top, 3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(ringSummary.remainLabel)
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(Color("AppInk").opacity(0.4))

                    Text(ringSummary.remainText)
                        .font(.system(size: 15.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(remainColor)
                }
                .padding(.top, 12)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 1)
                }
                .padding(.top, 13)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .background(Color("AppCard"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.08)))
    }

    // MARK: - By-Category Section

    private var sectionHeader: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("By category")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color("AppInk").opacity(0.48))

            Spacer()

            Text(breakdownFootText)
                .font(.system(size: 9.5, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(Color("AppInk").opacity(0.3))
        }
        .padding(.horizontal, 4)
        .padding(.top, 20)
        .padding(.bottom, 9)
    }

    private var breakdownCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(categories.enumerated()), id: \.element.persistentModelID) { index, category in
                BudgetBreakdownRow(
                    category: category,
                    spent: spent(for: category),
                    status: status(for: category)
                )

                if index < categories.count - 1 {
                    Divider()
                        .padding(.leading, 18)
                }
            }
        }
        .background(Color("AppCard"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.08)))
    }

    // MARK: - Uncategorized Block

    private var uncategorizedBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                HStack(spacing: 11) {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.primary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                        .frame(width: 9, height: 9)

                    Text("Uncategorized")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color("AppInk").opacity(0.62))
                }

                Spacer()

                Text(RupiahFormatter.string(from: uncategorizedTotal))
                    .font(.system(size: 12.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppInk").opacity(0.62))
            }

            Text("In your month total, outside the ring and the category limits above.")
                .font(.system(size: 11))
                .foregroundStyle(Color("AppInk").opacity(0.42))
                .lineSpacing(2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.022))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
        .padding(.top, 12)
    }

    // MARK: - No Categories Block

    private var noCategoriesBlock: some View {
        VStack(spacing: 5) {
            Text("No categories to break down")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Color("AppInk"))

            Text("Everything logged this month is uncategorized.")
                .font(.system(size: 12))
                .foregroundStyle(Color("AppInk").opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
        .padding(.top, 12)
    }

    // MARK: - Derived State

    private var transactionViewModel: TransactionViewModel {
        TransactionViewModel(modelContext: modelContext)
    }

    private var categoryViewModel: CategoryViewModel {
        CategoryViewModel(modelContext: modelContext)
    }

    /// The selected month's total spend, categorized or not — `0` also
    /// means "nothing spent this month," which is the empty-state trigger.
    /// A fetch failure falls back to `0` rather than surfacing an alert,
    /// matching this screen's siblings' read-only-display precedent.
    private var monthTotal: Int {
        (try? transactionViewModel.monthTotal(in: selectedMonth.startOfMonth)) ?? 0
    }

    /// A category's spend for the selected month, via `TransactionViewModel`'s
    /// already-tested aggregation.
    private func spent(for category: Category) -> Int {
        (try? transactionViewModel.spent(in: selectedMonth.startOfMonth, categoryID: category.persistentModelID)) ?? 0
    }

    private func status(for category: Category) -> BudgetStatus {
        categoryViewModel.budgetStatus(limit: category.monthlyLimit, spent: spent(for: category))
    }

    /// The month's spend attributed to a still-existing category — the sum
    /// of every current category's own `spent(for:)`, excluding
    /// uncategorized spend, which the ring deliberately doesn't include.
    private var totalSpent: Int {
        categories.reduce(0) { $0 + spent(for: $1) }
    }

    /// The sum of every current category's monthly limit, treating no limit
    /// as `0` — per the issue's accepted behavior, this always reflects
    /// today's limits regardless of which month is being viewed.
    private var totalLimit: Int {
        categories.reduce(0) { $0 + ($1.monthlyLimit ?? 0) }
    }

    private var uncategorizedTotal: Int {
        (try? transactionViewModel.uncategorizedTotal(in: selectedMonth.startOfMonth)) ?? 0
    }

    private var ringSummary: BudgetRingSummary {
        BudgetRingSummary.make(spent: totalSpent, totalLimit: totalLimit)
    }

    /// The overall ring's status, from the same `CategoryViewModel.budgetStatus(limit:spent:)`
    /// every row below also uses — fed the summed total limit (`nil` when
    /// there is no budget at all) and the summed categorized spend.
    private var ringStatus: BudgetStatus {
        categoryViewModel.budgetStatus(limit: totalLimit > 0 ? totalLimit : nil, spent: totalSpent)
    }

    // MARK: - Derived Styling

    /// The ring's progress-arc color: the shared over/at-limit status colors
    /// for `.over`/`.atLimit`, or the app's accent color otherwise.
    private var ringColor: Color {
        switch ringStatus {
        case .over:
            Color("BudgetOver")
        case .atLimit:
            Color("BudgetAtLimit")
        case .under, .noLimit:
            Color("AppAccent")
        }
    }

    /// The centered percentage text's color — stays ink for `.atLimit`,
    /// unlike `ringColor`, only switching to the over-budget red for
    /// `.over`.
    private var ringTextColor: Color {
        ringStatus == .over ? Color("BudgetOver") : Color("AppInk")
    }

    private var remainColor: Color {
        ringSummary.isOverBudget ? Color("BudgetOver") : Color("AppInk")
    }

    // MARK: - Derived Text

    private var breakdownFootText: String {
        "\(categories.count) CATEGORIES"
    }
}

// MARK: - Previews

#Preview("Populated") {
    @Previewable @State var selectedMonth: MonthKey = .current
    BudgetView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.richContainer())
}

#Preview("No categories, has spend") {
    @Previewable @State var selectedMonth: MonthKey = .current
    BudgetView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.noCategoriesContainer())
}

#Preview("Month empty") {
    @Previewable @State var selectedMonth: MonthKey = MonthKey.current.next()
    BudgetView(selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.richContainer())
}
