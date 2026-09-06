//
//  BudgetRingView.swift
//  SpendWise
//

import SwiftUI

/// The Budget screen's (#18) summary-card donut ring: a track circle plus a
/// colored progress arc, with the percentage and "OF BUDGET" caption
/// centered inside it.
///
/// This view only draws what it's told — `fraction` (already capped to
/// `0...1`, see `BudgetRingSummary.ringFraction`) and the two colors are
/// entirely the caller's responsibility to derive from a `BudgetStatus`, the
/// same "consume a pre-computed value, don't reclassify it" contract
/// `BudgetBar` follows for the by-category bars on this same screen.
struct BudgetRingView: View {

    // MARK: - Properties

    /// The ring's fill fraction, already clamped to `0...1`.
    let fraction: Double

    /// The progress arc's color — resolved by the caller from the overall
    /// `BudgetStatus` (accent color for `.under`/`.noLimit`, the shared
    /// amber/red status colors for `.atLimit`/`.over`).
    let ringColor: Color

    /// The centered percentage text's color — resolved by the caller;
    /// notably stays the app's ink color for `.atLimit`, unlike `ringColor`,
    /// only switching to the over-budget red for `.over`.
    let percentTextColor: Color

    /// The centered percentage text, e.g. `"62%"`, or `"—"` when no budget
    /// exists to measure against.
    let percentText: String

    /// The diameter of the ring, matching the source mockup's `126×126`
    /// summary-card ring.
    private let diameter: CGFloat = 126

    /// The stroke width of both the track and the progress arc, matching
    /// the mockup's `stroke-width="13"`.
    private let lineWidth: CGFloat = 13

    // MARK: - Body

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(percentText)
                    .font(.system(size: 25, weight: .semibold, design: .monospaced))
                    .foregroundStyle(percentTextColor)

                Text("OF BUDGET")
                    .font(.system(size: 8.5, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(Color("AppInk").opacity(0.4))
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        BudgetRingView(fraction: 0.4, ringColor: Color("AppAccent"), percentTextColor: Color("AppInk"), percentText: "40%")
        BudgetRingView(fraction: 1.0, ringColor: Color("BudgetAtLimit"), percentTextColor: Color("AppInk"), percentText: "100%")
        BudgetRingView(fraction: 1.0, ringColor: Color("BudgetOver"), percentTextColor: Color("BudgetOver"), percentText: "138%")
        BudgetRingView(fraction: 0, ringColor: Color("AppAccent"), percentTextColor: Color("AppInk"), percentText: "—")
    }
    .padding()
}
