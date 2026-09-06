//
//  EveryCategoryGoneEmptyStateView.swift
//  SpendWise
//

import SwiftUI

/// The Categories screen's (#15) empty state: shown when every category has
/// been deleted.
///
/// The copy deliberately reassures that this is safe: existing expenses
/// aren't gone, they're just Uncategorized now and still count toward the
/// month total — matching the design mockup's wording exactly, since a
/// blank "no categories" screen could otherwise read as data loss.
struct EveryCategoryGoneEmptyStateView: View {

    // MARK: - Properties

    let onAddCategory: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            dashedDotRow

            VStack(spacing: 7) {
                Text("Every category is gone")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("AppInk"))

                Text("Existing expenses are safe — they're all Uncategorized now, and still count toward your month total. Add a category to start setting limits again.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("AppInk").opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button("Add a category", action: onAddCategory)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(Capsule().fill(Color("AppAccent")))
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 40)
        .background(Color("AppCard"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.primary.opacity(0.08)))
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    // MARK: - Subviews

    /// Three dashed rounded squares, standing in for the category color
    /// dots now that there are none — matching the mockup's icon.
    private var dashedDotRow: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.primary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                    .frame(width: 11, height: 11)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    EveryCategoryGoneEmptyStateView(onAddCategory: {})
        .padding()
        .background(Color("AppSurface"))
}
