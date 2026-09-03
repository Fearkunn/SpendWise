//
//  Category.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import Foundation
import SwiftData

/// A spending category with an optional monthly budget limit and a color
/// token used to render it consistently across the UI.
///
/// - Note: This name collides with the Objective-C runtime's `Category`
///   typedef (`objc/runtime.h`, transitively visible) in explicit
///   type-annotation position — e.g. `: Category`, `FetchDescriptor<Category>()`
///   — though not in constructor calls (`Category(name:...)`) or contexts
///   where Swift's contextual inference already pins down the type. This
///   has already broken two test files. When an explicit annotation is
///   needed, especially in test targets, qualify it as `SpendWise.Category`
///   to avoid an ambiguous-type-lookup compiler error.
@Model
final class Category {

    // MARK: - Properties

    /// The category's display name.
    var name: String

    /// The monthly spending limit for this category, in whole Rupiah.
    /// `nil` means the category has no limit.
    var monthlyLimit: Int?

    /// A token identifying which color to render this category with.
    /// Mapping the token to an actual color is a View-layer concern.
    var colorToken: String

    /// The transactions currently assigned to this category.
    ///
    /// `deleteRule: .nullify` is load-bearing: deleting a category must
    /// never delete its transactions. Instead each affected transaction's
    /// `category` becomes `nil` and it shows up as "Uncategorized" — a
    /// guarantee enforced at the model layer so no ViewModel ever needs a
    /// reference to another ViewModel to implement it.
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []

    // MARK: - Initializers

    init(name: String, monthlyLimit: Int? = nil, colorToken: String) {
        self.name = name
        self.monthlyLimit = monthlyLimit
        self.colorToken = colorToken
    }
}
