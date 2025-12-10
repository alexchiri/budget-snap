//
//  BudgetSnapApp.swift
//  BudgetSnap
//
//  Privacy-First Budget Tracking via Screenshots
//

import SwiftUI
import SwiftData

@main
struct BudgetSnapApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Budget.self,
            Category.self
        ])

        // Ensure Application Support directory exists
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            do {
                try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Could not create Application Support directory: \(error)")
            }
        }

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
