//
//  NotificationManager.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import Foundation
import UserNotifications
import CoreData

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Request notification permissions
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    // Check notification authorization status
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // Schedule a notification for a task
    func scheduleTaskNotification(for task: Task) {
        // Remove any existing notifications for this task
        if let notificationID = task.notificationID {
            cancelNotification(withID: notificationID)
        }
        
        // Check if the task has a due date and time
        guard let dueDate = task.dueDate else { return }
        
        // Create a combined date with the due date and time (if available)
        var notificationDate = dueDate
        
        if task.hasTimeReminder, let dueTime = task.dueTime {
            // Extract time components from dueTime
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: dueTime)
            
            // Create a new date by combining the due date with the time components
            notificationDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                            minute: timeComponents.minute ?? 0,
                                            second: 0,
                                            of: dueDate) ?? dueDate
        }
        
        // Only schedule if the date is in the future
        guard notificationDate > Date() else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Due: \(task.title ?? "Untitled Task")"
        
        if let details = task.details, !details.isEmpty {
            content.body = details
        } else {
            content.body = "Your task is due now."
        }
        
        content.sound = .default
        content.badge = 1
        
        // Add task ID to the notification for identification
        if let taskID = task.id?.uuidString {
            content.userInfo = ["taskID": taskID]
        }
        
        // Create trigger based on the notification date
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create a unique identifier for this notification
        let notificationID = UUID().uuidString
        
        // Create the request
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                // Save the notification ID to the task
                DispatchQueue.main.async {
                    task.notificationID = notificationID
                    
                    // Save the context if possible
                    if let context = task.managedObjectContext {
                        do {
                            try context.save()
                        } catch {
                            print("Error saving notification ID: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // Cancel a specific notification
    func cancelNotification(withID id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    }
    
    // Cancel all notifications for a task
    func cancelTaskNotifications(for task: Task) {
        if let notificationID = task.notificationID {
            cancelNotification(withID: notificationID)
            task.notificationID = nil
            
            // Save the context if possible
            if let context = task.managedObjectContext {
                do {
                    try context.save()
                } catch {
                    print("Error removing notification ID: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Cancel all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification response when user taps on it
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if the notification is for a task
        if let taskID = userInfo["taskID"] as? String {
            // Post a notification to navigate to the task
            NotificationCenter.default.post(name: Notification.Name("OpenTask"), object: nil, userInfo: ["taskID": taskID])
        }
        
        completionHandler()
    }
    
    // Reschedule notifications for all incomplete tasks
    func rescheduleAllTaskNotifications(in context: NSManagedObjectContext) {
        // First, cancel all existing notifications
        cancelAllNotifications()
        
        // Fetch all incomplete tasks with due dates
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "completed == NO"),
            NSPredicate(format: "dueDate != nil")
        ])
        
        do {
            let tasks = try context.fetch(fetchRequest)
            
            // Schedule notifications for each task
            for task in tasks {
                scheduleTaskNotification(for: task)
            }
        } catch {
            print("Error fetching tasks for notification rescheduling: \(error.localizedDescription)")
        }
    }
} 