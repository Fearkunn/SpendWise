//
//  CategorySwatchPicker.swift
//  SpendWise
//

import SwiftUI

/// The 8-swatch color palette grid used by the category add/edit sheet
/// (#16) to choose a `Category.colorToken`, with a selection ring on the
/// active swatch.
///
/// Pulled out of `CategorySheetView` into `Views/Components/` since it's a
/// self-contained, reusable picker rather than sheet-specific chrome — the
/// same shape as `BudgetBar`/`CategoryRow` living here instead of alongside
/// a single screen.
struct CategorySwatchPicker: View {

    // MARK: - Properties

    let selectedToken: String
    let onSelect: (String) -> Void

    private let swatchSize: CGFloat = 34
    private let swatchCornerRadius: CGFloat = 11
    private let columns = [GridItem(.adaptive(minimum: 34), spacing: 10)]

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(CategoryViewModel.colorPalette, id: \.self) { token in
                swatch(for: token)
            }
        }
    }

    // MARK: - Swatch

    private func swatch(for token: String) -> some View {
        let isSelected = token == selectedToken

        return Button {
            onSelect(token)
        } label: {
            RoundedRectangle(cornerRadius: swatchCornerRadius, style: .continuous)
                .fill(CategoryColor.color(forToken: token))
                .frame(width: swatchSize, height: swatchSize)
                .overlay(
                    // Mockup: a 2px ink ring at the swatch's edge plus a 2px
                    // inset white shadow, so the active swatch reads as a
                    // ring with a visible gap rather than a border flush
                    // against the fill color. Approximated here with two
                    // nested strokes rather than SwiftUI's `shadow`, which
                    // has no direct "inset" equivalent.
                    RoundedRectangle(cornerRadius: swatchCornerRadius, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: isSelected ? 2 : 0)
                        .padding(2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: swatchCornerRadius, style: .continuous)
                        .strokeBorder(isSelected ? Color("AppInk") : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var selected: String = CategoryViewModel.colorPalette[2]
    CategorySwatchPicker(selectedToken: selected, onSelect: { selected = $0 })
        .padding()
}
