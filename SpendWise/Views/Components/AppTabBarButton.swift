//
//  AppTabBarButton.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import SwiftUI

/// A single segment of `AppTabBar`: an outlined (or, when selected, filled)
/// icon shape stacked above the tab's label.
///
/// Design note: in the source mockup, only the Transactions icon filled
/// solid when active while Budget and Categories stayed outline-only even
/// when selected — selection there was communicated mainly through label
/// weight/color and a background tint. That asymmetry reads as an
/// inconsistency once reproduced faithfully in SwiftUI, so all three icons
/// fill on selection here for visual consistency; selection is still
/// reinforced the same way the mockup used (bold/dark label, muted label
/// otherwise, tinted segment background).
struct AppTabBarButton: View {

    // MARK: - Properties

    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    private let iconSide: CGFloat = 15

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                icon

                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(segmentBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Subviews

    private var icon: some View {
        let shape = RoundedRectangle(cornerRadius: tab.iconCornerRadius, style: .continuous)

        return shape
            .fill(isSelected ? Color.primary : .clear)
            .overlay(shape.strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.55), lineWidth: 1.5))
            .frame(width: iconSide, height: iconSide)
    }

    private var segmentBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? Color.primary.opacity(0.07) : .clear)
    }
}

// MARK: - Previews

#Preview {
    HStack {
        AppTabBarButton(tab: .transactions, isSelected: true, action: {})
        AppTabBarButton(tab: .budget, isSelected: false, action: {})
        AppTabBarButton(tab: .categories, isSelected: false, action: {})
    }
    .padding()
}
