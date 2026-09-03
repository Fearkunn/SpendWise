//
//  AppTabBar.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import SwiftUI

/// The floating pill tab bar shown at the bottom of the app shell.
///
/// A rounded, translucent/blurred container holding three equal-width
/// segments (`AppTabBarButton`) — one per `AppTab` — in place of a standard
/// iOS tab bar.
struct AppTabBar: View {

    // MARK: - Properties

    @Binding var selectedTab: AppTab

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                AppTabBarButton(tab: tab, isSelected: tab == selectedTab) {
                    withAnimation(.snappy(duration: 0.25)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(5)
        .background(pillBackground)
        .padding(.horizontal, 20)
    }

    // MARK: - Subviews

    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 14, x: 0, y: 6)
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var selectedTab: AppTab = .transactions

    ZStack(alignment: .bottom) {
        Color(.systemGroupedBackground).ignoresSafeArea()
        AppTabBar(selectedTab: $selectedTab)
    }
}
