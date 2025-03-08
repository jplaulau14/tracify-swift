//
//  Persistence.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create mock items
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        
        // Create mock tasks
        let taskTitles = ["Complete project proposal", "Schedule doctor appointment", "Buy groceries", "Pay utility bills", "Call mom"]
        let taskDetails = ["Finish the draft and send to team for review", "Book annual checkup with Dr. Smith", "Get milk, eggs, bread, and vegetables", "Water, electricity, and internet bills due this week", "Ask about her garden and new recipes"]
        
        for i in 0..<taskTitles.count {
            let newTask = Task(context: viewContext)
            newTask.id = UUID()
            newTask.title = taskTitles[i]
            newTask.details = taskDetails[i]
            newTask.createdAt = Date()
            newTask.dueDate = Calendar.current.date(byAdding: .day, value: Int.random(in: 1...7), to: Date())
            newTask.priority = Int16(Int.random(in: 0...2))
            newTask.completed = Bool.random()
        }
        
        // Demo habit data with multiple consistency patterns
        createMockHabits(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    // Create comprehensive mock habit data that demonstrates all consistency patterns
    @MainActor
    private static func createMockHabits(in viewContext: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()
        
        // ============= DAILY HABITS =============
        
        // 1. Daily habit with active streak
        let dailyActive = Habit(context: viewContext)
        dailyActive.id = UUID()
        dailyActive.name = "Meditation (Daily, Active)"
        dailyActive.icon = "heart.circle.fill"
        dailyActive.color = "blue"
        dailyActive.createdAt = calendar.date(byAdding: .day, value: -30, to: today)!
        dailyActive.consistencyType = ConsistencyType.daily.rawValue
        
        // Create streak for past 7 days (active streak)
        for i in 0..<7 {
            let streak = Streak(context: viewContext)
            streak.id = UUID()
            streak.date = calendar.date(byAdding: .day, value: -i, to: today)!
            streak.habit = dailyActive
        }
        
        // 2. Daily habit with broken streak
        let dailyBroken = Habit(context: viewContext)
        dailyBroken.id = UUID()
        dailyBroken.name = "Exercise (Daily, Broken)"
        dailyBroken.icon = "figure.walk"
        dailyBroken.color = "green"
        dailyBroken.createdAt = calendar.date(byAdding: .day, value: -30, to: today)!
        dailyBroken.consistencyType = ConsistencyType.daily.rawValue
        
        // Had streak for days 4-10 ago, but missed days 1-3 (broken streak)
        for i in 4..<10 {
            let streak = Streak(context: viewContext)
            streak.id = UUID()
            streak.date = calendar.date(byAdding: .day, value: -i, to: today)!
            streak.habit = dailyBroken
        }
        
        // ============= DAYS OF WEEK HABITS =============
        
        // 3. Specific days habit with active streak (Mon, Wed, Fri)
        let daysActive = Habit(context: viewContext)
        daysActive.id = UUID()
        daysActive.name = "Boxing (MWF, Active)"
        daysActive.icon = "figure.boxing"
        daysActive.color = "red"
        daysActive.createdAt = calendar.date(byAdding: .day, value: -45, to: today)!
        daysActive.consistencyType = ConsistencyType.daysOfWeek.rawValue
        daysActive.selectedDays = [.monday, .wednesday, .friday]
        
        // Create streaks for the past few weeks on correct days
        for i in 0..<21 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let weekday = calendar.component(.weekday, from: date)
            
            // Only create streaks on M/W/F (weekdays 2, 4, and 6)
            if weekday == 2 || weekday == 4 || weekday == 6 {
                let streak = Streak(context: viewContext)
                streak.id = UUID()
                streak.date = date
                streak.habit = daysActive
            }
        }
        
        // 4. Specific days habit with broken streak (Tue, Thu)
        let daysBroken = Habit(context: viewContext)
        daysBroken.id = UUID()
        daysBroken.name = "Piano Lessons (TTh, Broken)"
        daysBroken.icon = "pianokeys"
        daysBroken.color = "purple"
        daysBroken.createdAt = calendar.date(byAdding: .day, value: -45, to: today)!
        daysBroken.consistencyType = ConsistencyType.daysOfWeek.rawValue
        daysBroken.selectedDays = [.tuesday, .thursday]
        
        // Create streaks for past weeks but miss the most recent Tuesday or Thursday
        for i in 0..<21 {
            // Skip last week to create broken streak
            if i < 7 {
                continue
            }
            
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let weekday = calendar.component(.weekday, from: date)
            
            // Only create streaks on T/Th (weekdays 3 and 5)
            if weekday == 3 || weekday == 5 {
                let streak = Streak(context: viewContext)
                streak.id = UUID()
                streak.date = date
                streak.habit = daysBroken
            }
        }
        
        // ============= INTERVAL HABITS =============
        
        // 5. Every X days habit with active streak (every 3 days)
        let intervalActive = Habit(context: viewContext)
        intervalActive.id = UUID()
        intervalActive.name = "Deep Clean (Every 3 Days, Active)"
        intervalActive.icon = "spray.sparkle"
        intervalActive.color = "teal"
        intervalActive.createdAt = calendar.date(byAdding: .day, value: -30, to: today)!
        intervalActive.consistencyType = ConsistencyType.interval.rawValue
        intervalActive.intervalDays = 3
        
        // Create streak for every 3 days, including the most recent one
        var currentDate = intervalActive.createdAt!
        while currentDate <= today {
            let daysFromToday = calendar.dateComponents([.day], from: currentDate, to: today).day ?? 0
            
            if daysFromToday <= 1 {
                // Most recent interval (today or yesterday)
                let streak = Streak(context: viewContext)
                streak.id = UUID()
                streak.date = currentDate
                streak.habit = intervalActive
            } else if daysFromToday % 3 == 0 {
                // Past intervals
                if Bool.random() {  // Add some variation
                    let streak = Streak(context: viewContext)
                    streak.id = UUID()
                    streak.date = currentDate
                    streak.habit = intervalActive
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 3, to: currentDate)!
        }
        
        // 6. Every X days habit with broken streak (every 2 days)
        let intervalBroken = Habit(context: viewContext)
        intervalBroken.id = UUID()
        intervalBroken.name = "Jogging (Every 2 Days, Broken)"
        intervalBroken.icon = "figure.run"
        intervalBroken.color = "orange"
        intervalBroken.createdAt = calendar.date(byAdding: .day, value: -30, to: today)!
        intervalBroken.consistencyType = ConsistencyType.interval.rawValue
        intervalBroken.intervalDays = 2
        
        // Create streak for every 2 days, but miss the most recent ones
        currentDate = intervalBroken.createdAt!
        while currentDate <= today {
            let daysFromToday = calendar.dateComponents([.day], from: currentDate, to: today).day ?? 0
            
            if daysFromToday > 4 && daysFromToday % 2 == 0 {
                // Create streaks in the past but not the most recent ones
                let streak = Streak(context: viewContext)
                streak.id = UUID()
                streak.date = currentDate
                streak.habit = intervalBroken
            }
            
            currentDate = calendar.date(byAdding: .day, value: 2, to: currentDate)!
        }
        
        // ============= MAX SKIP HABITS =============
        
        // 7. Don't skip X days habit with active streak (max 1 day skip)
        let skipActive = Habit(context: viewContext)
        skipActive.id = UUID()
        skipActive.name = "Learn Thai (Max 1 Skip, Active)"
        skipActive.icon = "character.book.closed"
        skipActive.color = "yellow"
        skipActive.createdAt = calendar.date(byAdding: .day, value: -20, to: today)!
        skipActive.consistencyType = ConsistencyType.maxSkipDays.rawValue
        skipActive.maxSkipDays = 1
        
        // Create streak pattern with at most 1 day skipped between completions
        // Creating a pattern like: Yes, Yes, No, Yes, Yes, No, Yes (most recent)
        for i in stride(from: 0, to: 15, by: 3) {
            // First day in pattern
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let streak = Streak(context: viewContext)
                streak.id = UUID()
                streak.date = date
                streak.habit = skipActive
            }
            
            // Second day in pattern
            if let date = calendar.date(byAdding: .day, value: -(i+1), to: today) {
                let streak = Streak(context: viewContext)
                streak.id = UUID()
                streak.date = date
                streak.habit = skipActive
            }
            
            // Skip the third day (but never exceed maxSkipDays = 1)
        }
        
        // 8. Don't skip X days habit with broken streak (max 2 days skip)
        let skipBroken = Habit(context: viewContext)
        skipBroken.id = UUID()
        skipBroken.name = "Read Book (Max 2 Skip, Broken)"
        skipBroken.icon = "book.fill"
        skipBroken.color = "pink"
        skipBroken.createdAt = calendar.date(byAdding: .day, value: -25, to: today)!
        skipBroken.consistencyType = ConsistencyType.maxSkipDays.rawValue
        skipBroken.maxSkipDays = 2
        
        // Create a pattern where sometimes we exceed the max skip days
        // Recent pattern: good streaks 10-20 days ago, then too many skipped days (>2) recently
        for i in 0..<25 {
            if i > 9 && i < 20 {
                if i % 3 != 0 {  // Skip every 3rd day (within max skip limit)
                    let streak = Streak(context: viewContext)
                    streak.id = UUID()
                    streak.date = calendar.date(byAdding: .day, value: -i, to: today)!
                    streak.habit = skipBroken
                }
            } else if i > 20 {
                // Add a few older streaks
                if i % 4 == 0 {
                    let streak = Streak(context: viewContext)
                    streak.id = UUID()
                    streak.date = calendar.date(byAdding: .day, value: -i, to: today)!
                    streak.habit = skipBroken
                }
            }
        }
    }

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tracify")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
