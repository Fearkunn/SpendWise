//
//  ExpenseDeleteToastView.swift
//  SpendWise
//

import SwiftUI

/// The floating toast shown after an attempted expense deletion (#14): a
/// status glyph, a message, an action ("Undo" for a successful delete,
/// "Retry" for a failed one), and a manual dismiss control. There is
/// deliberately no auto-dismiss timer, matching the mockup — it stays
/// visible until the user acts on it.
///
/// Presentation-only: `RootView` supplies the already-derived
/// `ExpenseDeleteToast` content and owns what `onAction`/`onDismiss` do
/// (undo-and-restore, or retry-the-same-delete).
struct ExpenseDeleteToastView: View {

    // MARK: - Properties

    let toast: ExpenseDeleteToast
    let onAction: () -> Void
    let onDismiss: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 9) {
            glyphMark

            Text(toast.message)
                .font(.caption)
                .foregroundStyle(tintColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onAction) {
                Text(toast.actionLabel)
                    .font(.caption.weight(.semibold))
                    .underline()
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Text("×")
                    .font(.system(size: 14))
                    .foregroundStyle(tintColor.opacity(0.5))
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Glyph

    private var glyphMark: some View {
        Text(toast.variant == .undo ? "✓" : "!")
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 15, height: 15)
            .background(Circle().fill(markColor))
    }

    // MARK: - Colors

    // `AppInk`/`BudgetOver` (#41) — the mockup's undo-variant colors are all
    // `rgba(28,26,23,...)` at varying opacity, i.e. `AppInk`; the
    // error-variant background/border/text reuse the same
    // `BudgetOver`-at-fixed-opacities treatment already established by
    // `ExpenseSheetView`'s inline error banner for the mockup's identical
    // `#FAEDE8` / `rgba(150,60,32,...)` error-red family.
    private var tintColor: Color {
        toast.variant == .undo ? Color("AppInk").opacity(0.62) : Color("BudgetOver")
    }

    private var markColor: Color {
        toast.variant == .undo ? Color("AppInk").opacity(0.45) : Color("BudgetOver")
    }

    private var backgroundColor: Color {
        toast.variant == .undo ? Color("AppInk").opacity(0.045) : Color("BudgetOver").opacity(0.08)
    }

    private var borderColor: Color {
        toast.variant == .undo ? Color("AppInk").opacity(0.1) : Color("BudgetOver").opacity(0.2)
    }
}

// MARK: - Previews

#Preview("Undo") {
    ExpenseDeleteToastView(toast: .make(outcome: .success), onAction: {}, onDismiss: {})
        .padding(.vertical, 40)
        .background(Color("AppSurface"))
}

#Preview("Error") {
    ExpenseDeleteToastView(toast: .make(outcome: .failure), onAction: {}, onDismiss: {})
        .padding(.vertical, 40)
        .background(Color("AppSurface"))
}
