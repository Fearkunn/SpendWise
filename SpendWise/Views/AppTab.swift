//
//  AppTab.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation

/// The three top-level tabs in the app shell, in the order they appear in
/// the floating pill tab bar.
enum AppTab: String, CaseIterable, Identifiable {
    case transactions
    case budget
    case categories

    // MARK: - Identifiable

    var id: String { rawValue }

    // MARK: - Presentation

    /// The label shown under this tab's icon.
    var title: String {
        switch self {
        case .transactions: "Transactions"
        case .budget: "Budget"
        case .categories: "Categories"
        }
    }

    /// The corner radius used to render this tab's icon shape. Each tab
    /// gets a deliberately different silhouette — a barely-rounded square,
    /// a full circle, and a more rounded square — rather than the same icon
    /// recolored, per the design mockup.
    var iconCornerRadius: CGFloat {
        switch self {
        case .transactions: 3
        case .budget: 999
        case .categories: 5
        }
    }
}
