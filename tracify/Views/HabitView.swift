//
//  HabitView.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import SwiftUI

struct HabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.createdAt, ascending: false)],
        animation: .default
    )
    private var habits: FetchedResults<Habit>
    
    @State private var isShowingNewHabitSheet = false
    @State private var searchText = ""
    
    // State for handling UI updates
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F2F5FF"),
                        colorScheme == .dark ? Color(hex: "212121") : Color(hex: "FFFFFF")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    if habits.isEmpty {
                        emptyStateView
                    } else {
                        // Custom Search Bar
                        searchBar
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        // Habits List
                        ScrollView {
                            VStack(spacing: 20) {
                                // Active Habits Header
                                sectionHeader(title: "Active Habits", icon: "heart.text.square", count: habits.count)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                
                                habitList
                                
                                // Extra padding at bottom
                                Color.clear.frame(height: 100)
                            }
                            .padding(.top, 8)
                        }
                        .refreshable {
                            // Could add pull-to-refresh logic here
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Filter or sort action
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color(hex: "5E6BE8"))
                    }
                }
            }
            .sheet(isPresented: $isShowingNewHabitSheet) {
                NewHabitView()
            }
            .onNotification(name: Notification.Name("ShowNewHabitSheet")) { _ in
                isShowingNewHabitSheet = true
            }
            .onNotification(name: Notification.Name("HabitUpdated")) { _ in
                // Refresh the view whenever any habit is updated
                refreshID = UUID()
            }
        }
    }
    
    // MARK: - Views
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search habits...", text: $searchText)
                .padding(10)
                .disableInputAccessoryView() // Disable input toolbar to avoid constraint issues
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .frame(height: 44)
    }
    
    private func sectionHeader(title: String, icon: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "5E6BE8"))
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "5E6BE8").opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(Color(hex: "5E6BE8"))
        }
    }
    
    private var habitList: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredHabits, id: \.id) { habit in
                HabitCard(habit: habit)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Filtered Habits
    
    private var filteredHabits: [Habit] {
        if searchText.isEmpty {
            return Array(habits)
        } else {
            return habits.filter {
                $0.name?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(Color(hex: "5E6BE8").opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "5E6BE8"))
            }
            .padding(.bottom, 20)
            
            // Text
            Text("No Habits Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
            
            Text("Start tracking your habits to build consistency and reach your goals.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Button
            Button(action: {
                isShowingNewHabitSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create New Habit")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(height: 50)
                .frame(minWidth: 200)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "5E6BE8"), Color(hex: "6D79FF")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(25)
                .shadow(color: Color(hex: "5E6BE8").opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
}

struct HabitCard: View {
    let habit: Habit
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isShowingDetails = false
    @State private var isPressed = false
    @State private var showCheckInConfirmation = false
    @State private var checkedInToday: Bool = false
    @State private var isCheckingIn = false // Animation state for check-in
    
    // For forcing refresh of the view
    @State private var refreshID = UUID()
    
    // Get habit color as Color object
    private var habitColor: Color {
        Color.fromString(habit.color)
    }
    
    // Get gradient based on habit color
    private var habitGradient: LinearGradient {
        let baseColor = habitColor
        // Create slightly darker version for gradient
        let darkerColor = Color(
            hue: baseColor.hue,
            saturation: min(baseColor.saturation * 1.1, 1.0),
            brightness: baseColor.brightness * 0.85
        )
        
        return LinearGradient(
            gradient: Gradient(colors: [baseColor, darkerColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "343434") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                        radius: 8, x: 0, y: 4)
            
            // Content
            VStack(spacing: 0) {
                // Header with habit name and icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(habitColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: habit.icon ?? "heart.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(habitColor)
                    }
                    
                    Text(habit.name ?? "Unnamed Habit")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                    
                    Spacer()
                    
                    // Check-in button with different appearances based on today's status
                    Button(action: {
                        if !checkedInToday {
                            checkInButtonTapped()
                        } else {
                            // If already checked in, show a toast or alert
                            withAnimation {
                                showCheckInConfirmation = true
                            }
                            
                            // Hide toast after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCheckInConfirmation = false
                                }
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(checkedInToday 
                                      ? habitColor 
                                      : habitColor.opacity(0.15))
                                .frame(width: 40, height: 40)
                                .scaleEffect(isCheckingIn ? 1.2 : 1.0)
                            
                            if checkedInToday {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(habitColor)
                            }
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .scaleEffect(isCheckingIn ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCheckingIn)
                }
                .padding()
                
                // Streak visualization
                VStack(spacing: 16) {
                    // Streak counters
                    HStack(spacing: 24) {
                        // Current streak
                        VStack(spacing: 4) {
                            Text("\(habit.calculateCurrentStreak())")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(habitColor)
                            
                            Text("Current")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 70)
                        
                        // Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1, height: 40)
                        
                        // Longest streak
                        VStack(spacing: 4) {
                            Text("\(habit.calculateLongestStreak())")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(habitColor)
                            
                            Text("Longest")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 70)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Weekly streak visualization
                    weeklyProgress
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            
            // Check-in confirmation toast
            if showCheckInConfirmation {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text("Already checked in today, good job!")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(habitColor)
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .zIndex(1)
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Show press animation
            withAnimation {
                isPressed = true
            }
            
            // Small delay before showing details
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
                isShowingDetails = true
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            HabitDetailView(habit: habit)
        }
        .onAppear {
            // Check if already logged in for today when view appears
            checkIfLoggedToday()
        }
        .onNotification(name: Notification.Name("HabitUpdated")) { notification in
            // Check if this is the habit that was updated
            if let updatedHabitID = notification.userInfo?["habitID"] as? UUID,
               let thisHabitID = habit.id,
               updatedHabitID == thisHabitID {
                // Force view to refresh by updating the refreshID
                refreshID = UUID()
            }
        }
        .id(refreshID) // Force full refresh when ID changes
    }
    
    // Weekly progress circles
    private var weeklyProgress: some View {
        let streaks = (habit.streaks as? Set<Streak>)?.compactMap { $0.date } ?? []
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let date = Calendar.current.date(byAdding: .day, value: -6 + index, to: Date())!
                    let hasStreak = streaks.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    VStack(spacing: 4) {
                        ZStack {
                            // Background circle
                            Circle()
                                .fill(hasStreak ? habitColor : Color.gray.opacity(0.15))
                                .frame(width: 30, height: 30)
                            
                            // Checkmark for completed days
                            if hasStreak {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        // Highlight for today
                        .overlay(
                            Circle()
                                .stroke(isToday ? habitColor : Color.clear, lineWidth: 2)
                                .padding(-2)
                        )
                        
                        Text(dayLetter(for: date))
                            .font(.system(size: 11))
                            .foregroundColor(isToday ? habitColor : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
    // Check if already logged today
    private func checkIfLoggedToday() {
        if let existingStreaks = habit.streaks as? Set<Streak> {
            checkedInToday = existingStreaks.contains { streak in
                guard let date = streak.date else { return false }
                return Calendar.current.isDateInToday(date)
            }
        } else {
            checkedInToday = false
        }
    }
    
    // Check-in button action with animations
    private func checkInButtonTapped() {
        // Animation sequence
        withAnimation {
            isCheckingIn = true
        }
        
        // Create the streak after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            addStreakForToday()
            
            // End animation
            withAnimation {
                isCheckingIn = false
            }
        }
    }
    
    private func addStreakForToday() {
        let today = Date()
        
        // Check if we already have a streak for today
        if let existingStreaks = habit.streaks as? Set<Streak>,
           existingStreaks.contains(where: { streak in
               guard let date = streak.date else { return false }
               return Calendar.current.isDateInToday(date)
           }) {
            // Already marked for today
            checkedInToday = true
            return
        }
        
        // Create new streak for today
        let newStreak = Streak(context: viewContext)
        newStreak.id = UUID()
        newStreak.date = today
        newStreak.habit = habit
        
        do {
            try viewContext.save()
            // Update state to reflect the check-in
            checkedInToday = true
            
            // Show success confirmation
            withAnimation {
                showCheckInConfirmation = true
            }
            
            // Hide toast after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCheckInConfirmation = false
                }
            }
        } catch {
            let nsError = error as NSError
            print("Error adding streak: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingDeleteConfirmation = false
    @State private var selectedTab = 0 // 0: Calendar, 1: History
    @State private var isShowingEditSheet = false
    
    // For forcing refresh of the view
    @State private var refreshID = UUID()
    
    // Get habit color as Color object
    private var habitColor: Color {
        Color.fromString(habit.color)
    }
    
    private var sortedStreaks: [Date] {
        let streaksSet = habit.streaks as? Set<Streak> ?? []
        return streaksSet.compactMap { $0.date }.sorted(by: >)
    }
    
    // Get consistency pattern info
    private var consistencyType: ConsistencyType {
        return ConsistencyType(rawValue: habit.consistencyType) ?? .daily
    }
    
    // Consistency pattern card
    private var consistencyPatternCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(habitColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: consistencyType.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(habitColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(consistencyType.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                    
                    // Description
                    Text(getPatternDescription())
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            
            // Display calendar days if using days of week pattern
            if consistencyType == .daysOfWeek && !habit.selectedDays.isEmpty {
                Divider()
                    .padding(.horizontal)
                
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        let isSelected = habit.selectedDays.contains(day)
                        
                        Text(day.shortName)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(isSelected ? 
                                         habitColor.opacity(0.9) : 
                                         (colorScheme == .dark ? Color(hex: "333333") : Color(hex: "F5F5F5")))
                            )
                            .foregroundColor(isSelected ? .white : .secondary)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                        radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    // Get detailed pattern description based on consistency type
    private func getPatternDescription() -> String {
        switch consistencyType {
        case .daily:
            return "Complete every day"
            
        case .daysOfWeek:
            if habit.selectedDays.isEmpty {
                return "No specific days selected"
            } else if habit.selectedDays.count == 7 {
                return "Complete every day of the week"
            } else {
                let dayNames = habit.selectedDays
                    .sorted { $0.rawValue < $1.rawValue }
                    .map { $0.shortName }
                    .joined(separator: ", ")
                return "Complete on: \(dayNames)"
            }
            
        case .interval:
            let days = Int(habit.intervalDays)
            if days <= 0 || days == 1 {
                return "Complete every day"
            } else {
                return "Complete every \(days) days"
            }
            
        case .maxSkipDays:
            let days = Int(habit.maxSkipDays)
            if days <= 0 {
                return "Don't skip any days"
            } else if days == 1 {
                return "Don't skip more than 1 day in a row"
            } else {
                return "Don't skip more than \(days) days in a row"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F9FF"),
                    colorScheme == .dark ? Color(hex: "212121") : Color(hex: "FFFFFF")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Habit Header
                    VStack(spacing: 16) {
                        // Habit icon with background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [habitColor, habitColor.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: habitColor.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: habit.icon ?? "heart.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Habit name
                        Text(habit.name ?? "Unnamed Habit")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Consistency Pattern Info
                    VStack(spacing: 16) {
                        // Pattern header
                        HStack {
                            Text("CONSISTENCY PATTERN")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                            Spacer()
                        }
                        
                        // Pattern card
                        consistencyPatternCard
                    }
                    .padding(.bottom, 12)
                    
                    // Stats Cards
                    VStack(spacing: 16) {
                        // Stats header
                        HStack {
                            Text("STATISTICS")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                            Spacer()
                        }
                        
                        // Stats grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            // Current streak
                            statCard(
                                value: "\(habit.calculateCurrentStreak())",
                                label: "Current",
                                iconName: "flame.fill",
                                color: habitColor
                            )
                            
                            // Longest streak
                            statCard(
                                value: "\(habit.calculateLongestStreak())",
                                label: "Longest",
                                iconName: "chart.line.uptrend.xyaxis",
                                color: habitColor
                            )
                            
                            // Total check-ins
                            statCard(
                                value: "\(sortedStreaks.count)",
                                label: "Total",
                                iconName: "checkmark.circle.fill",
                                color: habitColor
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        TabButton(text: "Calendar", isSelected: selectedTab == 0) {
                            withAnimation {
                                selectedTab = 0
                            }
                        }
                        
                        TabButton(text: "History", isSelected: selectedTab == 1) {
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Tab content
                    if selectedTab == 0 {
                        // Calendar view
                        VStack(spacing: 12) {
                            ModernCalendarView(dates: sortedStreaks, accentColor: habitColor)
                                .frame(height: 320)
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                                        radius: 12, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    } else {
                        // History list
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Check-ins")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            if sortedStreaks.isEmpty {
                                Text("No check-ins yet")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 30)
                            } else {
                                ForEach(sortedStreaks.prefix(20), id: \.self) { date in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(habitColor)
                                            
                                        Text(date.formattedDateTime())
                                            .font(.system(size: 15))
                                            
                                        Spacer()
                                        
                                        if Calendar.current.isDateInToday(date) {
                                            Text("Today")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 4)
                                                .background(habitColor)
                                                .cornerRadius(12)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                    
                                    Divider()
                                        .padding(.leading)
                                        .opacity(0.5)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                                        radius: 12, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Edit button
                    Button(action: {
                        isShowingEditSheet = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Habit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(habitColor.opacity(0.1))
                        )
                        .foregroundColor(habitColor)
                        .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Delete button
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Habit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "FF3B30").opacity(0.1))
                        )
                        .foregroundColor(Color(hex: "FF3B30"))
                        .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Circle().fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text(habit.name ?? "Habit Details")
                    .font(.system(size: 17, weight: .semibold))
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditHabitView(habit: habit)
        }
        .alert("Delete Habit", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("Are you sure you want to delete this habit and all its tracking data? This cannot be undone.")
        }
        .onNotification(name: Notification.Name("HabitUpdated")) { notification in
            // Check if this is the habit that was updated
            if let updatedHabitID = notification.userInfo?["habitID"] as? UUID,
               let thisHabitID = habit.id,
               updatedHabitID == thisHabitID {
                // Force view to refresh by updating the refreshID
                refreshID = UUID()
            }
        }
        .id(refreshID) // Force full refresh when ID changes
    }
    
    private func statCard(value: String, label: String, iconName: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "343434") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                        radius: 6, x: 0, y: 3)
        )
    }
    
    private func deleteHabit() {
        viewContext.delete(habit)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error deleting habit: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct TabButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color(hex: "5E6BE8") : Color.clear)
                )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .opacity(isSelected ? 0 : 1)
        )
    }
}

struct ModernCalendarView: View {
    let dates: [Date]
    let accentColor: Color
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    // Fix duplicate raw values by using unique identifiers
    private enum Weekday: String, CaseIterable, Identifiable {
        case sun = "S", mon = "M", tue = "Tu", wed = "W", thu = "Th", fri = "F", sat = "Sa"
        var id: Self { self }
    }
    private let weekdays = Weekday.allCases
    
    @State private var selectedMonth = Date()
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            // Month selector
            HStack {
                Button(action: {
                    if let date = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
                        withAnimation {
                            selectedMonth = date
                        }
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Circle().fill(colorScheme == .dark ? Color(hex: "343434") : Color(hex: "F5F5F5")))
                }
                
                Spacer()
                
                Text(monthYearString(from: selectedMonth))
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    if let date = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                        withAnimation {
                            selectedMonth = date
                        }
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Circle().fill(colorScheme == .dark ? Color(hex: "343434") : Color(hex: "F5F5F5")))
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays) { weekday in
                    Text(weekday.rawValue)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        let hasCheckIn = dates.contains { calendar.isDate($0, inSameDayAs: date) }
                        let isToday = calendar.isDateInToday(date)
                        
                        ZStack {
                            // Background circle for completed days
                            if hasCheckIn {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 32, height: 32)
                            }
                            
                            // Today indicator
                            if isToday && !hasCheckIn {
                                Circle()
                                    .stroke(accentColor, lineWidth: 1.5)
                                    .frame(width: 32, height: 32)
                            }
                            
                            // Day number
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 15, weight: isToday ? .medium : .regular))
                                .foregroundColor(
                                    hasCheckIn ? .white :
                                        (isToday ? accentColor :
                                            (calendar.component(.month, from: date) != calendar.component(.month, from: selectedMonth) ?
                                                .secondary.opacity(0.5) : .primary)
                                        )
                                )
                        }
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        // Get the range of days in the selected month
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start))
        else {
            return []
        }
        
        let monthLastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthFirstDay)!
        
        // Include days from previous month to fill the first week
        let firstWeekday = calendar.component(.weekday, from: monthFirstDay)
        var days: [Date?] = []
        
        // Add previous month's days
        if firstWeekday > 1 {
            for day in 1..<firstWeekday {
                if let date = calendar.date(byAdding: .day, value: -day, to: monthFirstDay) {
                    days.insert(date, at: 0)
                }
            }
        }
        
        // Add current month's days
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthFirstDay)!.count
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: monthFirstDay) {
                days.append(date)
            }
        }
        
        // Add next month's days to complete the last week
        let remainingDays = 42 - days.count // 6 weeks × 7 days
        for day in 0..<remainingDays {
            if let date = calendar.date(byAdding: .day, value: day + 1, to: monthLastDay) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct NewHabitView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var name = ""
    @State private var selectedIcon = "heart.circle.fill"
    @State private var selectedColor = "5E6BE8" // Default blue
    
    // Consistency pattern states
    @State private var selectedConsistencyType: ConsistencyType = .daily
    @State private var selectedWeekdays: [Weekday] = []
    @State private var intervalDays: Int = 2
    @State private var maxSkipDays: Int = 1
    
    // Modern colors with hex codes
    private let colorOptions = [
        "5E6BE8", // Blue
        "FF9D42", // Orange
        "4CD964", // Green
        "FF3B30", // Red
        "AF52DE", // Purple
        "FF2D55", // Pink
        "34C759", // Green
        "007AFF"  // Blue
    ]
    
    // Icon options with categories
    private let healthIcons = [
        "heart.circle.fill", "figure.walk", "figure.gymnastics", "figure.run", 
        "figure.yoga", "figure.mind.and.body", "lungs.fill", "ear.fill"
    ]
    
    private let lifestyleIcons = [
        "book.fill", "pencil", "bed.double.fill", "drop.fill", "leaf.fill", 
        "sun.max.fill", "moon.fill", "music.note", "eyes", "mustache.fill"
    ]
    
    private let customIcons = [
        "circle.grid.3x3.fill", "square.grid.3x3.fill", "plus", "checkmark", 
        "calendar", "star.fill", "flag.fill", "bolt.fill", "hand.thumbsup.fill"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F9FF"),
                    colorScheme == .dark ? Color(hex: "212121") : Color(hex: "FFFFFF")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Habit name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HABIT NAME")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("Name your habit", text: $name)
                            .font(.system(size: 17))
                            .padding()
                            .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .disableInputAccessoryView() // Disable input toolbar to avoid constraint issues
                    }
                    
                    // Consistency pattern selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONSISTENCY PATTERN")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 16) {
                            ForEach(ConsistencyType.allCases) { type in
                                Button(action: {
                                    withAnimation {
                                        selectedConsistencyType = type
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedConsistencyType == type ? 
                                                     Color(hex: selectedColor).opacity(0.15) : 
                                                     (colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: type.iconName)
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedConsistencyType == type ? 
                                                               Color(hex: selectedColor) : .gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(type.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                                            
                                            Text(type.description)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedConsistencyType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: selectedColor))
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        }
                        
                        // Additional options based on selected consistency type
                        if selectedConsistencyType == .daysOfWeek {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DAYS OF THE WEEK")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                HStack(spacing: 8) {
                                    ForEach(Weekday.allCases) { day in
                                        let isSelected = selectedWeekdays.contains(day)
                                        
                                        Button(action: {
                                            if isSelected {
                                                selectedWeekdays.removeAll { $0 == day }
                                            } else {
                                                selectedWeekdays.append(day)
                                            }
                                        }) {
                                            Text(day.shortName)
                                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(isSelected ? 
                                                             Color(hex: selectedColor).opacity(0.9) : 
                                                             (colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                                                )
                                                .foregroundColor(isSelected ? .white : .secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        } else if selectedConsistencyType == .interval {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("INTERVAL (DAYS)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                HStack {
                                    Text("Every")
                                        .foregroundColor(.secondary)
                                    
                                    Picker("", selection: $intervalDays) {
                                        ForEach(1...14, id: \.self) { days in
                                            Text(days == 1 ? "1 day" : "\(days) days").tag(days)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                    .padding(.horizontal)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        } else if selectedConsistencyType == .maxSkipDays {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MAXIMUM SKIP DAYS")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                HStack {
                                    Text("Don't skip more than")
                                        .foregroundColor(.secondary)
                                    
                                    Picker("", selection: $maxSkipDays) {
                                        ForEach(1...7, id: \.self) { days in
                                            Text(days == 1 ? "1 day" : "\(days) days").tag(days)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                    .padding(.horizontal)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                    
                                    Text("in a row")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Color selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COLOR")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                            ForEach(colorOptions, id: \.self) { color in
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 48, height: 48)
                                        .shadow(color: Color(hex: color).opacity(0.5), radius: 5, x: 0, y: 2)
                                    
                                    if color == selectedColor {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .frame(width: 48, height: 48)
                                    }
                                }
                                .padding(4)
                                .onTapGesture {
                                    selectedColor = color
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Icon selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ICON")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("Health & Fitness")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 8)
                        
                        iconGrid(icons: healthIcons)
                        
                        Text("Lifestyle")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 16)
                        
                        iconGrid(icons: lifestyleIcons)
                        
                        Text("Other")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 16)
                        
                        iconGrid(icons: customIcons)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Create button
                    Button(action: {
                        saveHabit()
                    }) {
                        Text("Create Habit")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 54)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(name.isEmpty ? Color.gray.opacity(0.5) : Color(hex: selectedColor))
                                    .shadow(color: name.isEmpty ? Color.clear : Color(hex: selectedColor).opacity(0.4), 
                                            radius: 8, x: 0, y: 4)
                            )
                    }
                    .disabled(name.isEmpty || (selectedConsistencyType == .daysOfWeek && selectedWeekdays.isEmpty))
                    .padding(.bottom, 30)
                }
                .padding(24)
            }
            .keyboardAdaptive()
            .hideKeyboardWhenTappedOutside()
        }
        .navigationTitle("New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color(hex: selectedColor))
            }
        }
        .onAppear {
            // Initialize with Monday, Wednesday, Friday selected for daysOfWeek
            selectedWeekdays = [.monday, .wednesday, .friday]
        }
    }
    
    private func iconGrid(icons: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
            ForEach(icons, id: \.self) { icon in
                ZStack {
                    Circle()
                        .fill(icon == selectedIcon ? 
                              Color(hex: selectedColor).opacity(0.15) : 
                              (colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(icon == selectedIcon ? Color(hex: selectedColor) : .gray)
                }
                .overlay(
                    Circle()
                        .stroke(
                            icon == selectedIcon ? Color(hex: selectedColor) : Color.clear, 
                            lineWidth: 2
                        )
                )
                .onTapGesture {
                    selectedIcon = icon
                }
            }
        }
    }
    
    private func saveHabit() {
        guard !name.isEmpty else { return }
        guard !(selectedConsistencyType == .daysOfWeek && selectedWeekdays.isEmpty) else { return }
        
        let newHabit = Habit(context: viewContext)
        newHabit.id = UUID()
        newHabit.name = name
        newHabit.icon = selectedIcon
        
        // Convert hex color to our named color system for storage
        // This is just to maintain compatibility with the existing fromString system
        let hexToNamedColor: [String: String] = [
            "5E6BE8": "blue",
            "FF9D42": "orange",
            "4CD964": "green",
            "FF3B30": "red",
            "AF52DE": "purple",
            "FF2D55": "pink",
            "34C759": "green",
            "007AFF": "blue"
        ]
        
        newHabit.color = hexToNamedColor[selectedColor] ?? "blue"
        newHabit.createdAt = Date()
        
        // Save consistency pattern data
        newHabit.consistencyType = selectedConsistencyType.rawValue
        
        switch selectedConsistencyType {
        case .daysOfWeek:
            newHabit.selectedDays = selectedWeekdays
        case .interval:
            newHabit.intervalDays = Int16(intervalDays)
        case .maxSkipDays:
            newHabit.maxSkipDays = Int16(maxSkipDays)
        case .daily:
            // Daily habit doesn't need additional configuration
            break
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving habit: \(nsError), \(nsError.userInfo)")
        }
    }
}

// Edit Habit View that builds on NewHabitView
struct EditHabitView: View {
    let habit: Habit
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    // Consistency pattern states
    @State private var selectedConsistencyType: ConsistencyType
    @State private var selectedWeekdays: [Weekday]
    @State private var intervalDays: Int
    @State private var maxSkipDays: Int
    
    // Initialize with current habit data
    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name ?? "")
        _selectedIcon = State(initialValue: habit.icon ?? "heart.circle.fill")
        
        // Convert named color to hex
        let namedToHex: [String: String] = [
            "blue": "5E6BE8",
            "orange": "FF9D42",
            "green": "4CD964",
            "red": "FF3B30",
            "purple": "AF52DE",
            "pink": "FF2D55",
            "teal": "5AC8FA",
            "yellow": "FFCC00"
        ]
        _selectedColor = State(initialValue: namedToHex[habit.color ?? "blue"] ?? "5E6BE8")
        
        // Initialize consistency pattern fields
        _selectedConsistencyType = State(initialValue: ConsistencyType(rawValue: habit.consistencyType) ?? .daily)
        _selectedWeekdays = State(initialValue: habit.selectedDays)
        _intervalDays = State(initialValue: Int(habit.intervalDays))
        _maxSkipDays = State(initialValue: Int(habit.maxSkipDays))
    }
    
    // Modern colors with hex codes
    private let colorOptions = [
        "5E6BE8", // Blue
        "FF9D42", // Orange
        "4CD964", // Green
        "FF3B30", // Red
        "AF52DE", // Purple
        "FF2D55", // Pink
        "34C759", // Green
        "007AFF"  // Blue
    ]
    
    // Icon options with categories
    private let healthIcons = [
        "heart.circle.fill", "figure.walk", "figure.gymnastics", "figure.run", 
        "figure.yoga", "figure.mind.and.body", "lungs.fill", "ear.fill"
    ]
    
    private let lifestyleIcons = [
        "book.fill", "pencil", "bed.double.fill", "drop.fill", "leaf.fill", 
        "sun.max.fill", "moon.fill", "music.note", "eyes", "mustache.fill"
    ]
    
    private let customIcons = [
        "circle.grid.3x3.fill", "square.grid.3x3.fill", "plus", "checkmark", 
        "calendar", "star.fill", "flag.fill", "bolt.fill", "hand.thumbsup.fill"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F9FF"),
                    colorScheme == .dark ? Color(hex: "212121") : Color(hex: "FFFFFF")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Habit name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HABIT NAME")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("Name your habit", text: $name)
                            .font(.system(size: 17))
                            .padding()
                            .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .disableInputAccessoryView() // Disable input toolbar to avoid constraint issues
                    }
                    
                    // Consistency pattern selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONSISTENCY PATTERN")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 16) {
                            ForEach(ConsistencyType.allCases) { type in
                                Button(action: {
                                    withAnimation {
                                        selectedConsistencyType = type
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedConsistencyType == type ? 
                                                     Color(hex: selectedColor).opacity(0.15) : 
                                                     (colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: type.iconName)
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedConsistencyType == type ? 
                                                               Color(hex: selectedColor) : .gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(type.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                                            
                                            Text(type.description)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedConsistencyType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: selectedColor))
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        }
                        
                        // Additional options based on selected consistency type
                        if selectedConsistencyType == .daysOfWeek {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DAYS OF THE WEEK")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                HStack(spacing: 8) {
                                    ForEach(Weekday.allCases) { day in
                                        let isSelected = selectedWeekdays.contains(day)
                                        
                                        Button(action: {
                                            if isSelected {
                                                selectedWeekdays.removeAll { $0 == day }
                                            } else {
                                                selectedWeekdays.append(day)
                                            }
                                        }) {
                                            Text(day.shortName)
                                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    Circle()
                                                        .fill(isSelected ? 
                                                             Color(hex: selectedColor).opacity(0.9) : 
                                                             (colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                                                )
                                                .foregroundColor(isSelected ? .white : .secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        } else if selectedConsistencyType == .interval {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("INTERVAL (DAYS)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                HStack {
                                    Text("Every")
                                        .foregroundColor(.secondary)
                                    
                                    Picker("", selection: $intervalDays) {
                                        ForEach(1...14, id: \.self) { days in
                                            Text(days == 1 ? "1 day" : "\(days) days").tag(days)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                    .padding(.horizontal)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        } else if selectedConsistencyType == .maxSkipDays {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("MAXIMUM SKIP DAYS")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 16)
                                
                                HStack {
                                    Text("Don't skip more than")
                                        .foregroundColor(.secondary)
                                    
                                    Picker("", selection: $maxSkipDays) {
                                        ForEach(1...7, id: \.self) { days in
                                            Text(days == 1 ? "1 day" : "\(days) days").tag(days)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                    .padding(.horizontal)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                    
                                    Text("in a row")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Color selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COLOR")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                            ForEach(colorOptions, id: \.self) { color in
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 48, height: 48)
                                        .shadow(color: Color(hex: color).opacity(0.5), radius: 5, x: 0, y: 2)
                                    
                                    if color == selectedColor {
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .frame(width: 48, height: 48)
                                    }
                                }
                                .padding(4)
                                .onTapGesture {
                                    selectedColor = color
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Icon selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ICON")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("Health & Fitness")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 8)
                        
                        iconGrid(icons: healthIcons)
                        
                        Text("Lifestyle")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 16)
                        
                        iconGrid(icons: lifestyleIcons)
                        
                        Text("Other")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 16)
                        
                        iconGrid(icons: customIcons)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Save button
                    Button(action: {
                        updateHabit()
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 54)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(name.isEmpty ? Color.gray.opacity(0.5) : Color(hex: selectedColor))
                                    .shadow(color: name.isEmpty ? Color.clear : Color(hex: selectedColor).opacity(0.4), 
                                            radius: 8, x: 0, y: 4)
                            )
                    }
                    .disabled(name.isEmpty || (selectedConsistencyType == .daysOfWeek && selectedWeekdays.isEmpty))
                    .padding(.bottom, 30)
                }
                .padding(24)
            }
            .keyboardAdaptive()
            .hideKeyboardWhenTappedOutside()
        }
        .navigationTitle("Edit Habit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color(hex: selectedColor))
            }
        }
    }
    
    private func iconGrid(icons: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
            ForEach(icons, id: \.self) { icon in
                ZStack {
                    Circle()
                        .fill(icon == selectedIcon ? 
                              Color(hex: selectedColor).opacity(0.15) : 
                              (colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5F5F5")))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(icon == selectedIcon ? Color(hex: selectedColor) : .gray)
                }
                .overlay(
                    Circle()
                        .stroke(
                            icon == selectedIcon ? Color(hex: selectedColor) : Color.clear, 
                            lineWidth: 2
                        )
                )
                .onTapGesture {
                    selectedIcon = icon
                }
            }
        }
    }
    
    private func updateHabit() {
        guard !name.isEmpty else { return }
        guard !(selectedConsistencyType == .daysOfWeek && selectedWeekdays.isEmpty) else { return }
        
        habit.name = name
        habit.icon = selectedIcon
        
        // Convert hex color to our named color system for storage
        // This is just to maintain compatibility with the existing fromString system
        let hexToNamedColor: [String: String] = [
            "5E6BE8": "blue",
            "FF9D42": "orange",
            "4CD964": "green",
            "FF3B30": "red",
            "AF52DE": "purple",
            "FF2D55": "pink",
            "34C759": "green",
            "007AFF": "blue"
        ]
        
        habit.color = hexToNamedColor[selectedColor] ?? "blue"
        
        // Update consistency pattern data
        habit.consistencyType = selectedConsistencyType.rawValue
        
        switch selectedConsistencyType {
        case .daysOfWeek:
            habit.selectedDays = selectedWeekdays
        case .interval:
            habit.intervalDays = Int16(intervalDays)
        case .maxSkipDays:
            habit.maxSkipDays = Int16(maxSkipDays)
        case .daily:
            // Daily habit doesn't need additional configuration
            break
        }
        
        do {
            try viewContext.save()
            
            // Post notification that a habit was updated with habit ID
            if let habitID = habit.id {
                NotificationCenter.default.post(
                    name: Notification.Name("HabitUpdated"), 
                    object: nil,
                    userInfo: ["habitID": habitID]
                )
            }
            
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating habit: \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    HabitView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}