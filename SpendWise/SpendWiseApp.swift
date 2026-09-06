//
//  SpendWiseApp.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 01/09/26.
//

import SwiftUI
import SwiftData

@main
struct SpendWiseApp: App {

    // MARK: - Properties

    /// The app's shared SwiftData persistence container, backed by the
    /// `Transaction` and `Category` models.
    private let modelContainer: ModelContainer = {
        let schema = Schema([Transaction.self, Category.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                // `AppAccent` (#41) is the app's deliberate warm-grey accent,
                // replacing the default system blue tint every interactive
                // control (buttons, symbol images) picks up by default.
                .tint(Color("AppAccent"))
        }
        .modelContainer(modelContainer)
    }
}
