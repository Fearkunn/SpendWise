//
//  CategoriesSummaryTests.swift
//  SpendWiseTests
//

import Testing
@testable import SpendWise

/// Covers `CategoriesSummary.subtitle(count:totalMonthlyLimit:)`.
struct CategoriesSummaryTests {

    @Test func zeroCategoriesReadsNoneYet() {
        #expect(CategoriesSummary.subtitle(count: 0, totalMonthlyLimit: 0) == "None yet")
    }

    @Test func someCategoriesReadsCountAndTotalLimit() {
        let subtitle = CategoriesSummary.subtitle(count: 7, totalMonthlyLimit: 4_700_000)
        #expect(subtitle == "7 categories · Rp4.700.000 in monthly limits")
    }

    @Test func oneCategoryDoesNotSingularizeTheWordCategories() {
        let subtitle = CategoriesSummary.subtitle(count: 1, totalMonthlyLimit: 500_000)
        #expect(subtitle == "1 categories · Rp500.000 in monthly limits")
    }

    @Test func categoriesWithNoLimitContributeZeroToTheTotal() {
        // A category with `monthlyLimit == nil` contributes `0`, not
        // excluded from the count — `totalMonthlyLimit` is the caller's
        // responsibility to sum that way (see `CategoriesView`).
        let subtitle = CategoriesSummary.subtitle(count: 2, totalMonthlyLimit: 500_000)
        #expect(subtitle == "2 categories · Rp500.000 in monthly limits")
    }
}
