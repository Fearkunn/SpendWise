//
//  BudgetBar.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 03/09/26.
//

import SwiftUI

/// A reusable budget progress bar shared by the Budget (#18) and Categories
/// (#15) screens, encoding the over-vs-at-limit visual distinction in one
/// place.
///
/// This view consumes a pre-computed `BudgetStatus` (see `Domain/BudgetStatus.swift`
/// and `CategoryViewModel.budgetStatus(limit:spent:)`) rather than
/// reclassifying `limit`/`spent` itself — per CLAUDE.md, that classification
/// logic lives in exactly one place. The caller also supplies `fraction`
/// (`Double(spent) / Double(limit)`, uncapped) so this view never needs to
/// know about `limit` being optional or guard a division by zero itself;
/// when `status` is `.noLimit` the value of `fraction` is ignored entirely.
///
/// - `.under` fills with the category's own color, no hatch.
/// - `.atLimit` fills amber with a steep, near-vertical pinstripe hatch.
/// - `.over` fills red with a shallower diagonal hatch, angled differently
///   from `.atLimit`'s so the two remain distinguishable without relying on
///   hue alone — a deliberate colorblind-safe choice from the app's design.
/// - `.noLimit` renders nothing: no track, no fill, no layout-occupying
///   placeholder.
///
/// Fill width is always capped at 100% of the track width, even when
/// `fraction` exceeds `1.0` (an over-budget bar reads as "full," not
/// overflowing its track).
struct BudgetBar: View {

    // MARK: - Style

    /// The two size variants this component supports, matching the two
    /// screens it's shared between.
    enum Style {
        /// The 8pt-tall variant used on the Budget screen.
        case budget

        /// The 6pt-tall variant used on the Categories screen.
        case categories

        /// The track/fill height for this variant.
        var height: CGFloat {
            switch self {
            case .budget: 8
            case .categories: 6
            }
        }
    }

    // MARK: - Properties

    /// How this category's spending compares to its limit. Governs both the
    /// fill color/hatch treatment and whether anything renders at all.
    let status: BudgetStatus

    /// `Double(spent) / Double(limit)`, uncapped — the caller's
    /// responsibility to compute so this view never has to special-case a
    /// `nil` or zero limit. Ignored when `status` is `.noLimit`.
    let fraction: Double

    /// The category's own color, used for the fill when `status` is
    /// `.under`. Mapping `Category.colorToken` to a `Color` is left to the
    /// caller, per that property's doc comment.
    let categoryColor: Color

    /// Which of the two size variants to render.
    let style: Style

    /// Semi-transparent white stripes, matching the source mockup's
    /// `rgba(255,255,255,.42)` hatch overlay. A literal, not a themed app
    /// color — it's an effect drawn on top of a status fill color, not UI
    /// chrome that needs to adapt to light/dark.
    private static let hatchStripeColor = Color.white.opacity(0.42)

    /// `.atLimit`'s hatch angle: a near-vertical pinstripe, matching the
    /// mockup's `repeating-linear-gradient(90deg, ...)`. Expressed here as
    /// the stripes' own rotation away from vertical (`0°` = perfectly
    /// vertical), not the CSS gradient-axis convention.
    private static let atLimitHatchAngle = Angle.degrees(0)

    /// `.over`'s hatch angle: a shallower diagonal, matching the mockup's
    /// `repeating-linear-gradient(115deg, ...)`. `115°` in CSS's
    /// gradient-axis convention is `25°` past `90°`, and a gradient axis
    /// rotation carries through directly to the perpendicular stripe
    /// rotation — hence `25°` away from vertical here, distinct from
    /// `.atLimit`'s `0°`.
    private static let overHatchAngle = Angle.degrees(25)

    // MARK: - Body

    var body: some View {
        if case .noLimit = status {
            EmptyView()
        } else {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.07))

                    fill(trackWidth: geometry.size.width)
                }
            }
            .frame(height: style.height)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func fill(trackWidth: CGFloat) -> some View {
        let fillWidth = trackWidth * Self.cappedFraction(fraction)

        ZStack(alignment: .leading) {
            Capsule()
                .fill(fillColor)

            if let hatchAngle {
                HatchPattern(angle: hatchAngle, stripeColor: Self.hatchStripeColor)
                    .clipShape(Capsule())
            }
        }
        .frame(width: fillWidth, alignment: .leading)
    }

    // MARK: - Fill Styling

    private var fillColor: Color {
        switch status {
        case .noLimit:
            // Unreachable: `body` returns `EmptyView()` before this is read.
            .clear
        case .under:
            categoryColor
        case .atLimit:
            // No "amber" system color exists; `.orange` is the closest
            // built-in, system-adaptive semantic tone, keeping with this
            // codebase's precedent (issue #10) of preferring system colors
            // over hardcoded hex where a reasonable one is available.
            .orange
        case .over:
            .red
        }
    }

    private var hatchAngle: Angle? {
        switch status {
        case .noLimit, .under:
            nil
        case .atLimit:
            Self.atLimitHatchAngle
        case .over:
            Self.overHatchAngle
        }
    }

    // MARK: - Fill Width Math

    /// Clamps a raw `spent / limit` fraction to the `0...1` range used for
    /// fill width, so an over-budget bar reads as full rather than
    /// overflowing its track.
    static func cappedFraction(_ fraction: Double) -> Double {
        max(0, min(fraction, 1))
    }
}

// MARK: - Hatch Pattern

/// A repeating diagonal stripe pattern, standing in for CSS's
/// `repeating-linear-gradient(<angle>, rgba(255,255,255,.42) 0 3px, transparent 3px 7px)`,
/// which has no direct SwiftUI equivalent.
///
/// Draws a field of parallel vertical lines spaced `stripePeriod` apart,
/// each `stripeWidth` wide, across an area large enough to fully cover the
/// view's bounds after rotating by `angle` — then lets the caller clip the
/// result to the actual fill shape.
private struct HatchPattern: View {

    // MARK: - Properties

    let angle: Angle
    let stripeColor: Color

    /// Visible stripe width, matching the mockup's `0 3px` stop.
    private let stripeWidth: CGFloat = 3

    /// Distance between the start of one stripe and the start of the next,
    /// matching the mockup's `3px 7px` transparent stop (3pt stripe + 4pt
    /// gap = 7pt period).
    private let stripePeriod: CGFloat = 7

    // MARK: - Body

    var body: some View {
        Canvas { context, size in
            // The pattern is drawn across a square at least as large as the
            // view's diagonal, so that after rotation it still fully covers
            // every corner of the (unrotated) bounds.
            let coverage = (size.width * size.width + size.height * size.height).squareRoot()

            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: angle)
            context.translateBy(x: -coverage / 2, y: -coverage / 2)

            var stripes = Path()
            var x: CGFloat = 0
            while x <= coverage {
                stripes.move(to: CGPoint(x: x, y: 0))
                stripes.addLine(to: CGPoint(x: x, y: coverage))
                x += stripePeriod
            }

            context.stroke(stripes, with: .color(stripeColor), lineWidth: stripeWidth)
        }
    }
}

// MARK: - Previews

#Preview("Budget height (8pt)") {
    VStack(alignment: .leading, spacing: 16) {
        BudgetBar(status: .under, fraction: 0.45, categoryColor: .blue, style: .budget)
        BudgetBar(status: .atLimit, fraction: 1.0, categoryColor: .green, style: .budget)
        BudgetBar(status: .over, fraction: 1.4, categoryColor: .orange, style: .budget)
        BudgetBar(status: .noLimit, fraction: 0, categoryColor: .pink, style: .budget)
    }
    .padding()
}

#Preview("Categories height (6pt)") {
    VStack(alignment: .leading, spacing: 16) {
        BudgetBar(status: .under, fraction: 0.45, categoryColor: .blue, style: .categories)
        BudgetBar(status: .atLimit, fraction: 1.0, categoryColor: .green, style: .categories)
        BudgetBar(status: .over, fraction: 1.4, categoryColor: .orange, style: .categories)
        BudgetBar(status: .noLimit, fraction: 0, categoryColor: .pink, style: .categories)
    }
    .padding()
}

#Preview("All four states, both variants") {
    let rows: [(label: String, status: BudgetStatus, fraction: Double, color: Color)] = [
        ("Under (Transport)", .under, 0.55, .blue),
        ("At limit (Groceries)", .atLimit, 1.0, .green),
        ("Over (Dining out)", .over, 1.35, .orange),
        ("No limit (Fun)", .noLimit, 0, .pink)
    ]

    return VStack(alignment: .leading, spacing: 20) {
        ForEach(rows, id: \.label) { row in
            VStack(alignment: .leading, spacing: 6) {
                Text(row.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                BudgetBar(status: row.status, fraction: row.fraction, categoryColor: row.color, style: .budget)
                BudgetBar(status: row.status, fraction: row.fraction, categoryColor: row.color, style: .categories)
            }
        }
    }
    .padding()
}
