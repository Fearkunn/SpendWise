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

    /// The app's shared SwiftData persistence container.
    ///
    /// The schema is intentionally empty for now — the `Transaction` and
    /// `Category` model types land in a later issue and will be registered
    /// here once they exist. This property only wires up the container so
    /// the persistence stack is available from the app entry point.
    private let modelContainer: ModelContainer = {
        let schema = Schema([])
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
        }
        .modelContainer(modelContainer)
    }
}
