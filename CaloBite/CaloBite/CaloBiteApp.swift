//
//  CaloBiteApp.swift
//  CaloBite
//
//  Created by Giulliano Suarez on 6/8/26.
//

import SwiftUI
import SwiftData

@main
struct CaloBiteApp: App {
    // Setting up the SwiftData container
    let container: ModelContainer = {
        let schema = Schema([FoodReference.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
