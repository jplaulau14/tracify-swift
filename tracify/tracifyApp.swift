//
//  tracifyApp.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import SwiftUI

@main
struct tracifyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
