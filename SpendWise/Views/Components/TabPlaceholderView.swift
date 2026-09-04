//
//  TabPlaceholderView.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import SwiftUI

/// Minimal stand-in content for a tab, shown until that tab's real screen
/// lands in a later issue.
///
/// This exists to prove two things about the shell: that switching tabs
/// works, and that the selected month is genuinely shared — the month
/// stepper here isn't just plumbed and inert, paging it on one tab visibly
/// moves every other tab too, since all three placeholders bind to the same
/// `MonthKey`.
struct TabPlaceholderView: View {

    // MARK: - Properties

    let tab: AppTab
    @Binding var selectedMonth: MonthKey

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Text(tab.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Screen content lands in a later issue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            monthStepper
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Subviews

    private var monthStepper: some View {
        HStack(spacing: 24) {
            Button {
                selectedMonth = selectedMonth.previous()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }

            VStack(spacing: 2) {
                Text(selectedMonth.label)
                    .font(.headline)
                Text(selectedMonth.relativeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 170)

            Button {
                selectedMonth = selectedMonth.next()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var selectedMonth: MonthKey = .current
    TabPlaceholderView(tab: .transactions, selectedMonth: $selectedMonth)
}
