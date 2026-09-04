//
//  ExpenseSheetView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The add/edit expense sheet (#13): a bottom sheet with a large centered
/// amount field, a date picker plus month-aware quick-select chips, a
/// wrapping category chip picker (with a `None` option), and an optional
/// note field.
///
/// This is presented modally from `TransactionsView` via `.sheet(item:)`
/// and, despite being a sheet rather than a tab, is treated as a `Screens/`
/// file rather than a `Components/` one: it owns its own header/navigation
/// chrome and isn't reused by any other screen, matching `TransactionsView`'s
/// shape more than a shared sub-piece like `TransactionRow`.
///
/// Per CLAUDE.md, all validation and persistence stays in
/// `TransactionViewModel` (#7) — this view only collects raw draft state and
/// hands it to `add`/`update`/`delete` as-is, surfacing whatever
/// `TransactionValidationError` comes back in the inline error banner.
///
/// Two judgment calls not specified by the issue: a new expense's category
/// defaults to `None` (the mockup's own prototype state happens to default
/// to the first existing category, but the issue doesn't call for that, and
/// `None` is the less presumptuous default); and the category chip picker
/// is sorted alphabetically by name via `@Query`, rather than left in
/// creation order, for a stable, predictable picker order.
struct ExpenseSheetView: View {

    // MARK: - Mode

    enum Mode: Identifiable {
        case add
        case edit(Transaction)

        var id: String {
            switch self {
            case .add:
                "add"
            case .edit(let transaction):
                "edit-\(ObjectIdentifier(transaction))"
            }
        }
    }

    // MARK: - Properties

    let mode: Mode

    @Binding var selectedMonth: MonthKey

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var amountText: String
    @State private var date: Date
    @State private var category: Category?
    @State private var note: String
    @State private var errorMessage: String?

    // MARK: - Initializers

    /// - Parameters:
    ///   - mode: Whether this is a new expense or an edit of an existing
    ///     one; also seeds every draft field below.
    ///   - selectedMonth: The shared month binding threaded down from
    ///     `RootView`. Read to compute a new expense's default date and the
    ///     date chips/month-impact note, and written on a successful save so
    ///     the app jumps to the saved record's month.
    init(mode: Mode, selectedMonth: Binding<MonthKey>) {
        self.mode = mode
        self._selectedMonth = selectedMonth

        switch mode {
        case .add:
            _amountText = State(initialValue: "")
            _date = State(initialValue: ExpenseDraftDefaults.date(selectedMonth: selectedMonth.wrappedValue))
            _category = State(initialValue: nil)
            _note = State(initialValue: "")
        case .edit(let transaction):
            _amountText = State(initialValue: RupiahFormatter.groupedDigits(from: String(transaction.amount)))
            _date = State(initialValue: transaction.date)
            _category = State(initialValue: transaction.category)
            _note = State(initialValue: transaction.note)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let errorMessage {
                        errorBanner(errorMessage)
                    }

                    amountCard
                    dateCard
                    categoryCard
                    noteCard

                    if case .edit = mode {
                        deleteButton
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveLabel) { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Amount

    private var amountCard: some View {
        VStack(spacing: 8) {
            Text("AMOUNT")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Rp")
                    .font(.system(.title3, design: .monospaced, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 33, weight: .semibold, design: .monospaced))
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: amountText) { _, newValue in
                        amountText = RupiahFormatter.groupedDigits(from: newValue)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .expenseSheetCardBackground()
    }

    // MARK: - Date

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Date")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }

            HStack(spacing: 7) {
                ForEach(dateChips) { chip in
                    dateChipButton(chip)
                }
            }

            Divider()

            HStack(spacing: 8) {
                Circle()
                    .fill(monthImpactNote.isEmphasized ? Color.accentColor : Color.secondary.opacity(0.5))
                    .frame(width: 6, height: 6)

                Text(monthImpactNote.text)
                    .font(.caption)
                    .fontWeight(monthImpactNote.isEmphasized ? .semibold : .regular)
                    .foregroundStyle(monthImpactNote.isEmphasized ? Color.accentColor : .secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .expenseSheetCardBackground()
    }

    private func dateChipButton(_ chip: ExpenseDateChip) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: chip.date)

        return Button {
            date = chip.date
        } label: {
            Text(chip.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Color.primary : Color(.systemBackground))
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.13))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.subheadline.weight(.semibold))

            FlowLayout(spacing: 7, lineSpacing: 7) {
                categoryChipButton(name: "None", color: nil, isSelected: category == nil) {
                    category = nil
                }

                ForEach(categories) { candidate in
                    categoryChipButton(
                        name: candidate.name,
                        color: CategoryColor.color(forToken: candidate.colorToken),
                        isSelected: category?.persistentModelID == candidate.persistentModelID
                    ) {
                        category = candidate
                    }
                }
            }

            if category == nil {
                Text("Stays in your list and month total, but sits outside the category breakdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .expenseSheetCardBackground()
    }

    private func categoryChipButton(name: String, color: Color?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                categoryDot(color: color)

                Text(name)
                    .font(.caption.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.leading, 10)
            .padding(.trailing, 13)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? Color.primary.opacity(0.045) : Color(.systemBackground))
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.primary : Color.primary.opacity(0.1), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    /// A filled, softly-rounded square in the category's color, or — for
    /// `None` — a dashed hollow outline of the same shape, matching
    /// `TransactionRow.colorDot`'s established visual convention for "has a
    /// category" vs. "doesn't."
    @ViewBuilder
    private func categoryDot(color: Color?) -> some View {
        if let color {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 8, height: 8)
        } else {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Note

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Note")
                .font(.subheadline.weight(.semibold))

            TextField("Optional", text: $note)
                .font(.body)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.13))
                        .frame(height: 1)
                }

            if !noteHintText.isEmpty {
                Text(noteHintText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .expenseSheetCardBackground()
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteExpense()
        } label: {
            Text("Delete this expense")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 13)
        .foregroundStyle(Color.red)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.red.opacity(0.22))
        )
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("!")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 15, height: 15)
                .background(Circle().fill(Color.red))

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.red)
        }
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.red.opacity(0.2))
        )
    }

    // MARK: - Actions

    private var transactionViewModel: TransactionViewModel {
        TransactionViewModel(modelContext: modelContext)
    }

    private func save() {
        do {
            let savedDate: Date
            switch mode {
            case .add:
                let transaction = try transactionViewModel.add(amountText: amountText, date: date, note: note, category: category)
                savedDate = transaction.date
            case .edit(let transaction):
                try transactionViewModel.update(transaction, amountText: amountText, date: date, note: note, category: category)
                savedDate = transaction.date
            }

            // The month-impact note pre-announces this: saving jumps the
            // shared selected month to follow the saved record, so it never
            // silently vanishes from the list the user is looking at.
            selectedMonth = MonthKey(date: savedDate)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteExpense() {
        guard case .edit(let transaction) = mode else { return }

        do {
            try transactionViewModel.delete(transaction)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Derived State

    private var dateChips: [ExpenseDateChip] {
        ExpenseDateChip.quickSelectChips(selectedMonth: selectedMonth)
    }

    private var monthImpactNote: ExpenseMonthImpactNote {
        ExpenseMonthImpactNote.make(selectedMonth: selectedMonth, date: date)
    }

    private var noteHintText: String {
        ExpenseNoteHint.text(note: note, hasCategory: category != nil)
    }

    private var title: String {
        switch mode {
        case .add: "New expense"
        case .edit: "Edit expense"
        }
    }

    private var saveLabel: String {
        switch mode {
        case .add: "Add"
        case .edit: "Save"
        }
    }
}

// MARK: - Card Background

private extension View {
    /// The white, softly-rounded card background shared by every section of
    /// the expense sheet, matching the mockup's `#fff` / `18px` radius /
    /// `1px` hairline-border cards.
    func expenseSheetCardBackground() -> some View {
        background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
    }
}

// MARK: - Flow Layout

/// A minimal wrapping row layout for the category chip picker, standing in
/// for the mockup's `flex-wrap:wrap`, which has no direct built-in SwiftUI
/// equivalent. Kept private to this file, matching `BudgetBar.HatchPattern`'s
/// precedent for a layout helper only ever used by the one view that needs
/// it, rather than promoted to its own `Views/Components/` file.
private struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > 0, origin.x + size.width > maxWidth {
                origin.y += rowHeight + lineSpacing
                origin.x = 0
                rowHeight = 0
            }
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, origin.x - spacing)
        }

        return CGSize(width: proposal.width ?? totalWidth, height: origin.y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > bounds.minX, origin.x + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += rowHeight + lineSpacing
                rowHeight = 0
            }

            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Previews

#Preview("New expense") {
    @Previewable @State var selectedMonth: MonthKey = .current
    ExpenseSheetView(mode: .add, selectedMonth: $selectedMonth)
        .modelContainer(PreviewFixtures.richContainer())
}

#Preview("Edit expense") {
    @Previewable @State var selectedMonth: MonthKey = .current
    let container = PreviewFixtures.richContainer()
    let transaction = try! container.mainContext.fetch(FetchDescriptor<Transaction>()).first!
    return ExpenseSheetView(mode: .edit(transaction), selectedMonth: $selectedMonth)
        .modelContainer(container)
}
