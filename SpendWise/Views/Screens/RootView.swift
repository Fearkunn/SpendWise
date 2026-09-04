//
//  RootView.swift
//  SpendWise
//

import SwiftUI

/// The app's shell: a three-tab container (Transactions, Budget,
/// Categories) with a custom floating pill tab bar in place of the
/// standard iOS tab bar, and the single selected month shared across all
/// three tabs.
///
/// The selected month is transient UI state, not entity data, so per
/// CLAUDE.md it does not live on `TransactionViewModel` or
/// `CategoryViewModel` — it's held here as `@State` and threaded down to
/// each tab as a `Binding<MonthKey>`. Paging the month from any tab updates
/// this one source of truth, so every tab stays in sync.
///
/// Each tab's actual content is out of scope for this shell (see #12, #15,
/// #18) and shown here only as `TabPlaceholderView`.
struct RootView: View {

    // MARK: - Properties

    @State private var selectedTab: AppTab = .transactions
    @State private var selectedMonth: MonthKey = .current

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    tabContent(for: tab)
                        .tag(tab)
                }
            }
            .toolbar(.hidden, for: .tabBar)

            floatingTabBar
        }
    }

    // MARK: - Subviews

    /// Each tab's real content, where it exists — currently just
    /// Transactions (#12). Budget (#18) and Categories (#15) still show
    /// `TabPlaceholderView` until their own screens land.
    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .transactions:
            TransactionsView(selectedMonth: $selectedMonth)
        case .budget, .categories:
            TabPlaceholderView(tab: tab, selectedMonth: $selectedMonth)
        }
    }

    /// The pill tab bar, anchored to the bottom with a soft upward
    /// gradient behind it so content scrolling underneath fades out rather
    /// than being hard-clipped by the pill's backdrop.
    private var floatingTabBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .allowsHitTesting(false)

            AppTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
                .background(Color(.systemGroupedBackground))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Previews

#Preview {
    RootView()
}
