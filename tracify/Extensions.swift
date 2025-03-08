//
//  Extensions.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import SwiftUI

// MARK: - Habit Consistency Types
enum ConsistencyType: Int16, CaseIterable, Identifiable {
    case daily = 0
    case daysOfWeek = 1
    case interval = 2
    case maxSkipDays = 3
    
    var id: Int16 { self.rawValue }
    
    var name: String {
        switch self {
        case .daily: return "Daily"
        case .daysOfWeek: return "Specific Days"
        case .interval: return "Every X Days"
        case .maxSkipDays: return "Don't Skip X Days"
        }
    }
    
    var description: String {
        switch self {
        case .daily: 
            return "Complete every day"
        case .daysOfWeek:
            return "Complete on specific days of the week"
        case .interval:
            return "Complete every X days"
        case .maxSkipDays:
            return "Don't skip X days in a row"
        }
    }
    
    var iconName: String {
        switch self {
        case .daily: return "calendar.day.timeline.leading"
        case .daysOfWeek: return "calendar.badge.clock"
        case .interval: return "arrow.triangle.2.circlepath"
        case .maxSkipDays: return "calendar.badge.exclamationmark"
        }
    }
}

// Enum for days of the week
enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { self.rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static func fromString(_ string: String?) -> Color {
        guard let string = string else { return .blue }
        
        switch string.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "yellow": return .yellow
        case "pink": return .pink
        default: return .blue
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isPast: Bool {
        return self < Date()
    }
    
    var isWithinWeek: Bool {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return self >= oneWeekAgo && self <= Date()
    }
}

// MARK: - Task Extensions
extension Task {
    var priorityName: String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return "Low"
        }
    }
    
    var priorityColor: Color {
        switch priority {
        case 0: return .blue
        case 1: return .orange
        case 2: return .red
        default: return .blue
        }
    }
}

// MARK: - Streak Calculation
extension Habit {
    // Get/Set for days of the week
    var selectedDays: [Weekday] {
        get {
            guard let data = daysOfWeek else { return [] }
            do {
                return try JSONDecoder().decode([Weekday].self, from: data)
            } catch {
                print("Error decoding days of week: \(error)")
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                daysOfWeek = data
            } catch {
                print("Error encoding days of week: \(error)")
            }
        }
    }
    
    // Helper to check if a date matches the habit's consistency pattern
    func shouldCompleteOn(date: Date) -> Bool {
        let calendar = Calendar.current
        let consistencyTypeEnum = ConsistencyType(rawValue: consistencyType) ?? .daily
        
        switch consistencyTypeEnum {
        case .daily:
            return true
            
        case .daysOfWeek:
            // Check if the date's weekday matches any selected day
            let weekday = calendar.component(.weekday, from: date)
            return selectedDays.contains(where: { $0.rawValue == weekday })
            
        case .interval:
            // Check if the date falls on the interval pattern
            let intervalValue = max(1, Int(intervalDays)) // Ensure at least 1 day
            guard let habitStart = createdAt else { return false }
            
            let daysSinceStart = calendar.dateComponents([.day], from: habitStart, to: date).day ?? 0
            return daysSinceStart % intervalValue == 0
            
        case .maxSkipDays:
            // For maxSkipDays, any day can be a valid completion day
            // The streak calculation will handle the max skip days logic
            return true
        }
    }
    
    // Functions related to streak calculation
    
    // Check if a given date has a completed streak
    func hasStreak(on date: Date) -> Bool {
        guard let streaksSet = streaks as? Set<Streak> else { return false }
        let calendar = Calendar.current
        
        return streaksSet.contains { streak in
            guard let streakDate = streak.date else { return false }
            return calendar.isDate(streakDate, inSameDayAs: date)
        }
    }
    
    // Calculate the current streak based on consistency type
    func calculateCurrentStreak() -> Int {
        guard let streaksSet = streaks as? Set<Streak>, !streaksSet.isEmpty else {
            return 0
        }
        
        let sortedStreaks = streaksSet
            .compactMap { $0.date }
            .sorted(by: >)
            
        let calendar = Calendar.current
        let consistencyTypeEnum = ConsistencyType(rawValue: consistencyType) ?? .daily
        
        switch consistencyTypeEnum {
        case .daily:
            // Original daily streak calculation
            var currentStreak = 0
            var checkDate = Date()
            
            while true {
                // Skip dates where the habit shouldn't be completed
                if !shouldCompleteOn(date: checkDate) {
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                    continue
                }
                
                let dayStreaks = sortedStreaks.filter { calendar.isDate($0, inSameDayAs: checkDate) }
                if !dayStreaks.isEmpty {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            }
            
            return currentStreak
            
        case .daysOfWeek:
            // Count consecutive weeks where all scheduled days were completed
            var currentStreak = 0
            var checkDate = Date()
            
            // While we have streaks to check
            while true {
                let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkDate))!
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
                
                // Get all days in this week that should have had the habit completed
                var allDaysCompleted = true
                var currentDate = weekStart
                
                while currentDate <= weekEnd {
                    if shouldCompleteOn(date: currentDate) {
                        // This day should have been completed, check if it was
                        let completed = hasStreak(on: currentDate)
                        if !completed && !calendar.isDateInFuture(currentDate) {
                            allDaysCompleted = false
                            break
                        }
                    }
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                }
                
                if allDaysCompleted {
                    // All scheduled days in this week were completed
                    currentStreak += 1
                    // Move to previous week
                    checkDate = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
                } else {
                    break
                }
            }
            
            return currentStreak
            
        case .interval:
            // Count consecutive intervals where the habit was completed
            let intervalValue = max(1, Int(intervalDays))
            var currentStreak = 0
            guard let habitStart = createdAt else { return 0 }
            
            var checkDate = Date()
            // Get to the nearest interval date on or before today
            let daysSinceStart = calendar.dateComponents([.day], from: habitStart, to: checkDate).day ?? 0
            let daysToAdjust = daysSinceStart % intervalValue
            checkDate = calendar.date(byAdding: .day, value: -daysToAdjust, to: checkDate)!
            
            while true {
                if hasStreak(on: checkDate) || calendar.isDateInFuture(checkDate) {
                    if !calendar.isDateInFuture(checkDate) {
                        currentStreak += 1
                    }
                    // Move to previous interval
                    checkDate = calendar.date(byAdding: .day, value: -intervalValue, to: checkDate)!
                } else {
                    break
                }
            }
            
            return currentStreak
            
        case .maxSkipDays:
            // Count days in the streak as long as we don't exceed maxSkipDays in a row
            let maxSkip = max(1, Int(maxSkipDays))
            var currentStreak = 0
            var consecutiveSkips = 0
            var checkDate = Date()
            
            // Keep track of the last completion date
            var lastCompletionDate: Date?
            
            // First, check if there's a recent completion and if the streak is currently active
            let recentDays = 3 + maxSkip // Look at recent days (today + maximum allowed skip days)
            var hasRecentCompletion = false
            
            for i in 0..<recentDays {
                let date = calendar.date(byAdding: .day, value: -i, to: Date())!
                if hasStreak(on: date) {
                    hasRecentCompletion = true
                    break
                }
            }
            
            // If there's no recent completion, the streak is broken - return 0
            if !hasRecentCompletion {
                return 0
            }
            
            // Otherwise, calculate the current streak
            while true {
                if hasStreak(on: checkDate) {
                    // Habit was completed on this day
                    if let lastCompletion = lastCompletionDate {
                        // Check if we've exceeded the max skip threshold since last completion
                        let daysSinceLastCompletion = calendar.dateComponents([.day], from: checkDate, to: lastCompletion).day ?? 0
                        if daysSinceLastCompletion > maxSkip + 1 {
                            // Exceeded maximum consecutive skips - this is the start of a new streak
                            break
                        } else {
                            // Within allowed skip window, add to current streak
                            currentStreak += 1
                        }
                    } else {
                        // First completion date
                        currentStreak = 1
                    }
                    
                    // Update the last completion date
                    lastCompletionDate = checkDate
                    consecutiveSkips = 0
                } else if calendar.isDateInFuture(checkDate) {
                    // Future dates don't count as skips
                } else {
                    // Habit was not completed on this day
                    consecutiveSkips += 1
                    
                    // If we haven't found any completions yet, keep looking back
                    if lastCompletionDate == nil {
                        // Keep searching
                    } else if consecutiveSkips > maxSkip {
                        // Exceeded maximum consecutive skips - streak is broken
                        break
                    }
                }
                
                // Move to the previous day
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }
            
            return currentStreak
        }
    }
    
    // Calculate the total streaks (completions)
    func calculateTotalStreaks() -> Int {
        guard let streaksSet = streaks as? Set<Streak> else { return 0 }
        return streaksSet.count
    }
    
    // Calculate success rate
    func calculateSuccessRate() -> Double {
        let _ = ConsistencyType(rawValue: consistencyType) ?? .daily
        guard let creationDate = createdAt else { return 0 }
        
        let calendar = Calendar.current
        let _ = max(1, calendar.dateComponents([.day], from: creationDate, to: Date()).day ?? 1)
        
        // Count days that should have had the habit completed
        var daysToComplete = 0
        var date = creationDate
        
        while date <= Date() {
            if shouldCompleteOn(date: date) {
                daysToComplete += 1
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        // If no days to complete, return 100%
        if daysToComplete == 0 { return 1.0 }
        
        // Count completed days
        guard let streaksSet = streaks as? Set<Streak> else { return 0 }
        let completedDays = streaksSet.count
        
        return Double(completedDays) / Double(daysToComplete)
    }
    
    // Calculate longest streak
    func calculateLongestStreak() -> Int {
        guard let streaksSet = streaks as? Set<Streak>, !streaksSet.isEmpty else {
            return 0
        }
        
        let calendar = Calendar.current
        let consistencyTypeEnum = ConsistencyType(rawValue: consistencyType) ?? .daily
        
        // Approach depends on consistency type
        switch consistencyTypeEnum {
        case .daily:
            // For daily, we look for consecutive days
            let sortedDates = streaksSet
                .compactMap { $0.date }
                .sorted()
            
            var currentStreak = 1
            var longestStreak = 1
            
            for i in 1..<sortedDates.count {
                let previousDate = sortedDates[i-1]
                let currentDate = sortedDates[i]
                
                let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
                
                if daysBetween == 1 {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else if daysBetween > 1 {
                    currentStreak = 1
                }
            }
            
            return longestStreak
            
        case .daysOfWeek:
            // For specific days, we count consecutive weeks with all days completed
            return calculateConsecutiveWeeks(from: streaksSet)
            
        case .interval:
            // For intervals, we count consecutive intervals completed
            return calculateConsecutiveIntervals(from: streaksSet)
            
        case .maxSkipDays:
            // For max skip days, we find the longest streak where never exceeded max skip
            return calculateLongestNonSkippingStreak(from: streaksSet)
        }
    }
    
    // Helper function to calculate consecutive complete weeks
    private func calculateConsecutiveWeeks(from streaksSet: Set<Streak>) -> Int {
        guard !streaksSet.isEmpty, !selectedDays.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var startDate = streaksSet.compactMap { $0.date }.min() ?? Date()
        let endDate = Date()
        
        // Initialize to beginning of the week
        startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate))!
        
        var currentWeekStreak = 0
        var longestWeekStreak = 0
        var currentWeek = startDate
        
        while currentWeek <= endDate {
            // Get all days in this week - not using weekEnd, so removing it
            
            // Check if all required days in this week were completed
            var allCompletedForWeek = true
            
            // For each day in this week
            for dayOffset in 0...6 {
                let day = calendar.date(byAdding: .day, value: dayOffset, to: currentWeek)!
                
                // Skip days that are in the future
                if day > endDate {
                    break
                }
                
                // Check if this is a day that should be completed
                if shouldCompleteOn(date: day) {
                    // Check if it was completed
                    if !hasStreak(on: day) {
                        allCompletedForWeek = false
                        break
                    }
                }
            }
            
            if allCompletedForWeek {
                currentWeekStreak += 1
                longestWeekStreak = max(longestWeekStreak, currentWeekStreak)
            } else {
                currentWeekStreak = 0
            }
            
            // Move to next week
            currentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek)!
        }
        
        return longestWeekStreak
    }
    
    // Helper function to calculate consecutive intervals
    private func calculateConsecutiveIntervals(from streaksSet: Set<Streak>) -> Int {
        guard !streaksSet.isEmpty, let habitStart = createdAt else { return 0 }
        
        let intervalValue = max(1, Int(intervalDays))
        let calendar = Calendar.current
        let sortedDates = streaksSet.compactMap { $0.date }.sorted()
        
        var longestStreak = 0
        var currentStreak = 0
        // Fixing the Date?() initialization
        let _: Date? = nil
        
        // Calculate all interval dates from habit start to today
        var allIntervalDates = [Date]()
        var currentDate = habitStart
        let today = Date()
        
        while currentDate <= today {
            allIntervalDates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: intervalValue, to: currentDate)!
        }
        
        // Check each interval date - was it completed?
        for intervalDate in allIntervalDates {
            // If this interval date is in the future, we stop
            if intervalDate > today {
                break
            }
            
            // Check if we have a streak for this date (or within 1 day)
            let completed = sortedDates.contains { streakDate in
                return calendar.isDate(intervalDate, inSameDayAs: streakDate)
            }
            
            if completed {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
    
    // Helper function to calculate longest streak with max skip days
    private func calculateLongestNonSkippingStreak(from streaksSet: Set<Streak>) -> Int {
        guard !streaksSet.isEmpty else { return 0 }
        
        let maxSkip = max(1, Int(maxSkipDays))
        let calendar = Calendar.current
        let sortedDates = streaksSet.compactMap { $0.date }.sorted()
        
        var longestStreak = 0
        var currentStreak = 0
        var _ = 0 // Replaced skippedDays with _ since it's never read
        var lastDate: Date?
        
        for date in sortedDates {
            if let last = lastDate {
                let daysBetween = calendar.dateComponents([.day], from: last, to: date).day ?? 0
                
                if daysBetween <= maxSkip + 1 {
                    // Still within allowed skip window
                    _ = daysBetween - 1 // -1 because we're not counting the current day
                    currentStreak += daysBetween
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    // Too many skipped days, reset streak
                    currentStreak = 1
                    _ = 0
                }
            } else {
                // First date
                currentStreak = 1
            }
            
            lastDate = date
        }
        
        return longestStreak
    }
}

// Helper extension for Calendar
extension Calendar {
    func isDateInFuture(_ date: Date) -> Bool {
        return date > Date()
    }
}

// MARK: - Button Style Extensions
struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 10
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .shadow(color: backgroundColor.opacity(0.3), radius: 3, x: 0, y: 2)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var foregroundColor: Color = .blue
    var cornerRadius: CGFloat = 10
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .foregroundColor(foregroundColor.opacity(configuration.isPressed ? 0.7 : 1))
            .background(Color(.secondarySystemBackground))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(foregroundColor.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct FABButtonStyle: ButtonStyle {
    var backgroundColor: Color = .blue
    var foregroundColor: Color = .white
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(foregroundColor)
            .frame(width: 60, height: 60)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1))
            .cornerRadius(30)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.2 : 0.3), 
                    radius: configuration.isPressed ? 3 : 5, 
                    x: 0, 
                    y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Extension to provide easy access to the button styles
extension View {
    func primaryButtonStyle(backgroundColor: Color = .blue) -> some View {
        self.buttonStyle(PrimaryButtonStyle(backgroundColor: backgroundColor))
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func fabButtonStyle(backgroundColor: Color = .blue) -> some View {
        self.buttonStyle(FABButtonStyle(backgroundColor: backgroundColor))
    }
}

// MARK: - Color Theme System
struct AppTheme {
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let accent = Color("AccentColor")
    static let background = Color("BackgroundColor")
    static let cardBackground = Color("CardBackgroundColor")
    static let textPrimary = Color("TextPrimaryColor")
    static let textSecondary = Color("TextSecondaryColor")
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
    static let error = Color("ErrorColor")
    
    // Fallback system if assets aren't found
    static var primaryFallback: Color { Color(hex: "5E6BE8") }
    static var secondaryFallback: Color { Color(hex: "969AF8") }
    static var accentFallback: Color { Color(hex: "6D79FF") }
    static var backgroundFallback: Color { Color(hex: "F9FAFF") }
    static var cardBackgroundFallback: Color { Color(hex: "FFFFFF") }
    static var textPrimaryFallback: Color { Color(hex: "2D3142") }
    static var textSecondaryFallback: Color { Color(hex: "747B9D") }
    static var successFallback: Color { Color(hex: "4CD964") }
    static var warningFallback: Color { Color(hex: "FF9900") }
    static var errorFallback: Color { Color(hex: "FF3B30") }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design System Styles
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.08), 
                    radius: 15, x: 0, y: 5)
    }
}

struct SecondaryCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AppTheme.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05), 
                    radius: 8, x: 0, y: 3)
    }
}

struct ContentBackgroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.background)
            .edgesIgnoringSafeArea(.all)
    }
}

// Extension for easy access to design styles
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func secondaryCardStyle() -> some View {
        modifier(SecondaryCardStyle())
    }
    
    func contentBackground() -> some View {
        modifier(ContentBackgroundStyle())
    }
}

// MARK: - Color Component Extensions
extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            return (0, 0, 0, 0)
        }
        
        return (r, g, b, o)
    }
    
    var brightness: CGFloat {
        let components = self.components
        return ((components.red * 299) + (components.green * 587) + (components.blue * 114)) / 1000
    }
    
    var isDark: Bool {
        return brightness < 0.5
    }
    
    var hue: CGFloat {
        let components = self.components
        return Color.getHue(r: components.red, g: components.green, b: components.blue).0
    }
    
    var saturation: CGFloat {
        let components = self.components
        return Color.getHue(r: components.red, g: components.green, b: components.blue).1
    }
    
    // Helper method to convert RGB to HSV/HSB
    private static func getHue(r: CGFloat, g: CGFloat, b: CGFloat) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        let minValue = min(r, min(g, b))
        let maxValue = max(r, max(g, b))
        let delta = maxValue - minValue
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        let brightness = maxValue
        
        if delta != 0 {
            if maxValue == r {
                hue = (g - b) / delta + (g < b ? 6 : 0)
            } else if maxValue == g {
                hue = (b - r) / delta + 2
            } else {
                hue = (r - g) / delta + 4
            }
            
            hue /= 6
            saturation = maxValue == 0 ? 0 : delta / maxValue
        }
        
        return (hue, saturation, brightness)
    }
}

// MARK: - Keyboard Management
extension View {
    func hideKeyboardWhenTappedOutside() -> some View {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    @ViewBuilder
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptiveModifier())
    }

    // Add a function to disable keyboard's input assistant view (toolbars)
    // This helps avoid many layout constraint conflicts
    func disableInputAccessoryView() -> some View {
        return self.background(InputAccessoryDisabler())
    }
}

// Modifier to handle keyboard appearance and avoid constraint conflicts
struct KeyboardAdaptiveModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                    // Use animation to avoid constraint conflicts during keyboard transitions
                    withAnimation(.easeOut(duration: 0.16)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    // Use animation to avoid constraint conflicts during keyboard transitions
                    withAnimation(.easeIn(duration: 0.2)) {
                        keyboardHeight = 0
                    }
                }
            }
    }
}

// Helper component to disable keyboard input accessories
// This prevents the "assistantHeight" constraint conflicts
struct InputAccessoryDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        // Create invisible text field that can become first responder
        let textField = DisableToolbarTextField()
        textField.backgroundColor = .clear
        textField.isHidden = true
        view.addSubview(textField)
        
        // Make it a subview but don't let it be seen or used
        textField.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    // A text field subclass that disables the input assistant toolbar
    private class DisableToolbarTextField: UITextField {
        override init(frame: CGRect) {
            super.init(frame: frame)
            configureInputAssistant()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configureInputAssistant()
        }
        
        private func configureInputAssistant() {
            let assistantItem = self.inputAssistantItem
            assistantItem.leadingBarButtonGroups = []
            assistantItem.trailingBarButtonGroups = []
        }
    }
}

// MARK: - Notification Center Management
class NotificationManager {
    static let shared = NotificationManager()
    private var observers = [NSObjectProtocol]()
    
    func addObserver(for name: Notification.Name, object: Any? = nil, queue: OperationQueue? = .main, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        let observer = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: block)
        observers.append(observer)
        return observer
    }
    
    func removeObserver(_ observer: NSObjectProtocol) {
        if let index = observers.firstIndex(where: { $0 === observer }) {
            NotificationCenter.default.removeObserver(observers[index])
            observers.remove(at: index)
        }
    }
    
    func removeAllObservers() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }
}

// SwiftUI extension to handle notification observation lifecycle
struct NotificationObserver: ViewModifier {
    private let center = NotificationCenter.default
    let name: Notification.Name
    let onNotification: (Notification) -> Void
    
    init(name: Notification.Name, onNotification: @escaping (Notification) -> Void) {
        self.name = name
        self.onNotification = onNotification
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                center.addObserver(forName: name, object: nil, queue: .main, using: onNotification)
            }
            .onDisappear {
                center.removeObserver(self, name: name, object: nil)
            }
    }
}

extension View {
    func onNotification(name: Notification.Name, perform action: @escaping (Notification) -> Void) -> some View {
        self.modifier(NotificationObserver(name: name, onNotification: action))
    }
}
