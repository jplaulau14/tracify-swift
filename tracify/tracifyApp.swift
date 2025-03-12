//
//  tracifyApp.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import SwiftUI
import UserNotifications

@main
struct tracifyApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// App delegate to handle application lifecycle
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Suppress keyboard layout warnings by increasing the priority threshold for log messages
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        // Request notification permissions
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                // Schedule notifications for existing tasks
                DispatchQueue.main.async {
                    let context = PersistenceController.shared.container.viewContext
                    NotificationManager.shared.rescheduleAllTaskNotifications(in: context)
                }
            }
        }
        
        return true
    }
    
    // Handle time changes (e.g., timezone changes)
    func applicationSignificantTimeChange(_ application: UIApplication) {
        // Reschedule all notifications when time changes significantly
        let context = PersistenceController.shared.container.viewContext
        NotificationManager.shared.rescheduleAllTaskNotifications(in: context)
    }
    
    // Handle when app becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Reset badge count using the recommended API for iOS 17+
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error resetting badge count: \(error.localizedDescription)")
            }
        }
    }
}
