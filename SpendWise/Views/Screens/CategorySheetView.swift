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
/// Mirrors `ExpenseSheetView`'s (#13) shape and conventions exactly — same
/// `Mode` enum, same `NavigationStack`/toolbar chrome, same card background
/// and error-banner styling — since this is the same "bottom sheet with
/// Cancel / title / Add|Save" pattern applied to a different entity. Per
/// CLAUDE.md, all validation and persistence stays in `CategoryViewModel`
/// (#9) — this view only collects raw draft state and hands it to
/// `add`/`update`/`delete` as-is, surfacing whatever `CategoryValidationError`
/// comes back in the inline error banner.
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

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var limitText: String
    @State private var colorToken: String
    @State private var errorMessage: String?

    // MARK: - Initializers

    init(mode: Mode) {
        self.mode = mode

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
        NavigationStack {
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
            // `AppSurface` — same screen-backdrop token `ExpenseSheetView`
            // uses for its own sheet-panel background.
            .background(Color("AppSurface"))
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

    /// Deletes the category directly on tap, with no confirmation step.
    ///
    /// The confirmation dialog is explicitly out of scope for #16 (it needs
    /// its own affected-transactions-count copy, per the mockup's
    /// `confirmBody`). Rather than leaving this button silently doing
    /// nothing until that dialog exists — the same trap `CategoriesView`'s
    /// own no-op `onDeleteCategory` default was deliberately left in for
    /// #15 — this calls `CategoryViewModel.delete(_:)` immediately. This is
    /// an interim behavior only: it should be replaced by a real
    /// confirmation step in the issue that adds one.
    private var deleteButton: some View {
        Button(role: .destructive) {
            deleteCategory()
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

    private func deleteCategory() {
        guard case .edit(let category) = mode else { return }

        do {
            try categoryViewModel.delete(category)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
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
