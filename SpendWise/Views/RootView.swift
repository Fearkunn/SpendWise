//
//  RootView.swift
//  SpendWise
//

import SwiftUI

/// Placeholder root view shown while the app shell has no real screens yet.
///
/// This will be replaced once the transaction and category screens land in
/// later issues; for now it only confirms that the app launches and the
/// SwiftData container initializes successfully.
struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("SpendWise")
                .font(.title)
                .bold()

            Text("Setting things up…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview {
    RootView()
}
