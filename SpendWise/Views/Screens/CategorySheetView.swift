//
//  CategorySheetView.swift
//  SpendWise
//

import SwiftUI
import SwiftData

/// The add/edit category sheet (#16): a bottom sheet with a name field, a
/// monthly limit field (with a `Clear` action and hint copy explaining the
/// zero-limit rule), and the 8-swatch color picker.
///
/// Mirrors `ExpenseSheetView`'s (#13) shape and conventions — same `Mode`
/// enum, same card background and error-banner styling — since this is the
/// same "bottom sheet with Cancel / title / Add|Save" pattern applied to a
/// different entity. Per CLAUDE.md, all validation and persistence stays in
/// `CategoryViewModel` (#9) — this view only collects raw draft state and
/// hands it to `add`/`update`/`delete` as-is, surfacing whatever
/// `CategoryValidationError` comes back in the inline error banner.
///
/// **Header note (flagged fix, post-#16):** unlike `ExpenseSheetView`, this
/// does *not* use `NavigationStack` + `.navigationTitle`/`.toolbar`. The
/// mockup's header (`Design/SpendWise.dc.html`) is a fully custom 3-column
/// row — plain-text `Cancel`, a centered title, and a solid `AppAccent`
/// capsule for Save/Add, the same pill treatment as `TransactionsView`'s
/// "+ Expense" button — not a native nav bar with system-tinted text
/// buttons. `ExpenseSheetView` ships with this same native-toolbar mismatch,
/// but fixing it is out of scope here; it was already merged under a
/// separate, closed issue.
///
/// **Color picker note (flagged deviation from #9's original scope):** the
/// design mockup (`Design/SpendWise.dc.html`) wires every swatch's `onClick`
/// unconditionally, in both add and edit mode, to actually change the
/// draft's color — not just preview it. `CategoryViewModel.add`/`update`
/// (#9) originally had no way to accept a caller-chosen color; #9's
/// `update` even shipped with a passing test asserting the color token is
/// *never* touched by an edit. To let this sheet match the mockup's real
/// interaction rather than presenting non-functional swatches, both methods
/// gained an additive, defaulted `colorToken` parameter (see their doc
/// comments) — every pre-#16 call site is unaffected, and #9's existing
/// "leave color untouched" test still passes unchanged since it never
/// passes the new parameter.
///
/// One judgment call not specified by the issue: a new category's swatch
/// picker starts on `colorPalette`'s first entry, rather than mirroring the
/// mockup's "next unused color" pre-selection. Reproducing "next unused"
/// here would mean duplicating `CategoryViewModel`'s own color-assignment
/// logic in the View; simply starting on the first swatch avoids that
/// duplication; a small change to the ViewModel to also expose that
/// property is skipped to remain in scope for this issue.
///
/// **Delete handoff (#17):** `deleteButton` no longer calls
/// `CategoryViewModel.delete(_:)` itself. Category deletion always needs a
/// confirmation dialog with count-aware copy (unlike expense deletion,
/// which is unconfirmed and undo-based) — reproducing that here would
/// duplicate `CategoriesView`'s own confirmation-dialog state. Instead,
/// tapping "Delete category" dismisses this sheet and calls
/// `onRequestDelete`, matching the mockup's `askDeleteCat` exactly (it
/// closes the sheet and opens the confirmation dialog in the same step,
/// never stacking the two). `CategoriesView`, which already owns
/// `activeSheet`, is what actually presents the confirmation and calls
/// `CategoryViewModel.delete(_:)` once the user confirms.
struct CategorySheetView: View {

    // MARK: - Mode

    enum Mode: Identifiable {
        case add
        case edit(Category)

        var id: String {
            switch self {
            case .add:
                "add"
            case .edit(let category):
                "edit-\(ObjectIdentifier(category))"
            }
        }
    }

    // MARK: - Properties

    let mode: Mode

    /// Handles tapping "Delete category": handed the category being edited
    /// so the caller (`CategoriesView`) can present its own confirmation
    /// dialog. Defaults to a no-op via `init(mode:onRequestDelete:)` so
    /// every pre-#17 call site — namely this file's own previews — is
    /// unaffected.
    let onRequestDelete: (Category) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var limitText: String
    @State private var colorToken: String
    @State private var errorMessage: String?

    // MARK: - Initializers

    init(mode: Mode, onRequestDelete: @escaping (Category) -> Void = { _ in }) {
        self.mode = mode
        self.onRequestDelete = onRequestDelete

        switch mode {
        case .add:
            _name = State(initialValue: "")
            _limitText = State(initialValue: "")
            _colorToken = State(initialValue: CategoryViewModel.colorPalette[0])
        case .edit(let category):
            _name = State(initialValue: category.name)
            _limitText = State(initialValue: category.monthlyLimit.map { RupiahFormatter.groupedDigits(from: String($0)) } ?? "")
            _colorToken = State(initialValue: category.colorToken)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    if let errorMessage {
                        errorBanner(errorMessage)
                    }

                    nameCard
                    limitCard
                    colorCard

                    if case .edit = mode {
                        deleteButton
                    }
                }
                .padding(16)
            }
        }
        // `AppSurface` — same screen-backdrop token `ExpenseSheetView` uses
        // for its own sheet-panel background; applied to the whole column
        // (not just the `ScrollView`) so the custom header below matches it
        // too, now that there's no native nav bar providing its own fill.
        .background(Color("AppSurface"))
    }

    // MARK: - Header

    /// The mockup's custom 3-column header row: `Cancel` pinned leading,
    /// the title centered, and the Save/Add pill pinned trailing. Both side
    /// buttons are wrapped in `.frame(maxWidth: .infinity, ...)`, which
    /// splits the remaining space evenly regardless of each button's own
    /// width — the SwiftUI equivalent of the mockup's CSS grid
    /// `1fr auto 1fr`, keeping the title genuinely centered.
    private var header: some View {
        HStack(spacing: 0) {
            Button("Cancel") { dismiss() }
                .font(.system(size: 14))
                // `AppInk` at the mockup's `rgba(28,26,23,.55)` opacity,
                // matching the established `Color("AppInk").opacity(...)`
                // token convention used elsewhere in this file/screen family.
                .foregroundStyle(Color("AppInk").opacity(0.55))
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.system(size: 15.5, weight: .semibold))
                .lineLimit(1)
                .fixedSize()

            Button(action: save) {
                Text(saveLabel)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    // `AppAccent` — the same solid capsule treatment as
                    // `TransactionsView.addExpenseButton`'s "+ Expense" pill.
                    .background(Capsule().fill(Color("AppAccent")))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .buttonStyle(.plain)
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.07))
                .frame(height: 1)
        }
    }

    // MARK: - Name

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Name")
                .font(.subheadline.weight(.semibold))

            TextField("e.g. Groceries", text: $name)
                .font(.system(size: 17, weight: .medium))
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.13))
                        .frame(height: 1)
                }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .categorySheetCardBackground()
    }

    // MARK: - Monthly Limit

    private var limitCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Monthly limit")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button("Clear") { limitText = "" }
                    .font(.caption.weight(.semibold))
                    .disabled(!isClearEnabled)
                    // `AppAccent` when there's something to clear, matching
                    // the mockup's accent-colored `Clear`; a dimmed
                    // `.secondary` wash otherwise, matching its
                    // `rgba(28,26,23,.25)` disabled state.
                    .foregroundStyle(isClearEnabled ? Color("AppAccent") : Color.secondary.opacity(0.5))
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("Rp")
                    .font(.system(.subheadline, design: .monospaced, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("No limit", text: $limitText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 21, weight: .semibold, design: .monospaced))
                    .onChange(of: limitText) { _, newValue in
                        limitText = RupiahFormatter.groupedDigits(from: newValue)
                    }
            }
            .padding(.bottom, 6)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.primary.opacity(0.13))
                    .frame(height: 1)
            }

            Text(limitHintText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .categorySheetCardBackground()
    }

    // MARK: - Color

    private var colorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline.weight(.semibold))

            CategorySwatchPicker(selectedToken: colorToken, onSelect: { colorToken = $0 })
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .categorySheetCardBackground()
    }

    // MARK: - Delete

    /// Dismisses this sheet and hands off to `onRequestDelete` — see the
    /// "Delete handoff" note in this file's top doc comment.
    private var deleteButton: some View {
        Button(role: .destructive) {
            requestDelete()
        } label: {
            Text("Delete category")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 13)
        .foregroundStyle(Color("BudgetOver"))
        .background(Color("AppCard"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color("BudgetOver").opacity(0.22))
        )
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Text("!")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 15, height: 15)
                .background(Circle().fill(Color("BudgetOver")))

            Text(message)
                .font(.caption)
                .foregroundStyle(Color("BudgetOver"))
        }
        .padding(12)
        .background(Color("BudgetOver").opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color("BudgetOver").opacity(0.2))
        )
    }

    // MARK: - Actions

    private var categoryViewModel: CategoryViewModel {
        CategoryViewModel(modelContext: modelContext)
    }

    private func save() {
        do {
            switch mode {
            case .add:
                try categoryViewModel.add(name: name, monthlyLimitText: limitText, colorToken: colorToken)
            case .edit(let category):
                try categoryViewModel.update(category, name: name, monthlyLimitText: limitText, colorToken: colorToken)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Hands the category being edited to `onRequestDelete`, then dismisses
    /// this sheet — matching the mockup's `askDeleteCat`, which closes the
    /// sheet and opens the confirmation dialog in the same step.
    private func requestDelete() {
        guard case .edit(let category) = mode else { return }
        onRequestDelete(category)
        dismiss()
    }

    // MARK: - Derived State

    private var isClearEnabled: Bool {
        CategoryLimitHint.isClearEnabled(limitText: limitText)
    }

    private var limitHintText: String {
        CategoryLimitHint.text(limitText: limitText)
    }

    private var title: String {
        switch mode {
        case .add: "New category"
        case .edit: "Edit category"
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
    /// The card background shared by every section of the category sheet,
    /// matching `ExpenseSheetView.expenseSheetCardBackground()` exactly.
    func categorySheetCardBackground() -> some View {
        background(Color("AppCard"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
    }
}

// MARK: - Previews

#Preview("New category") {
    CategorySheetView(mode: .add)
        .modelContainer(PreviewFixtures.richContainer())
}

#Preview("Edit category") {
    let container = PreviewFixtures.richContainer()
    let category = try! container.mainContext.fetch(FetchDescriptor<Category>()).first!
    return CategorySheetView(mode: .edit(category))
        .modelContainer(container)
}
