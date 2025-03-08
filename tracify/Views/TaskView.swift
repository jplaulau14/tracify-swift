//
//  TaskView.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import SwiftUI

struct TaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Task.completed, ascending: true),
            NSSortDescriptor(keyPath: \Task.dueDate, ascending: true),
            NSSortDescriptor(keyPath: \Task.priority, ascending: false)
        ],
        animation: .default
    )
    private var tasks: FetchedResults<Task>
    
    @State private var isShowingNewTaskSheet = false
    @State private var searchText = ""
    
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
                    if tasks.isEmpty {
                        emptyStateView
                    } else {
                        // Custom Search Bar
                        searchBar
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        // Task Lists
                        ScrollView {
                            VStack(spacing: 20) {
                                // Today's Tasks Header
                                sectionHeader(title: "Today's Tasks", icon: "calendar", count: todayTasks.count)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                
                                if !todayTasks.isEmpty {
                                    taskGroup(tasks: todayTasks)
                                } else {
                                    noTasksMessage(message: "No tasks due today")
                                }
                                
                                // Upcoming Tasks Header
                                sectionHeader(title: "Upcoming", icon: "clock", count: upcomingTasks.count)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                
                                if !upcomingTasks.isEmpty {
                                    taskGroup(tasks: upcomingTasks)
                                } else {
                                    noTasksMessage(message: "No upcoming tasks")
                                }
                                
                                // Completed Tasks Header (if any)
                                if !completedTasks.isEmpty {
                                    sectionHeader(title: "Completed", icon: "checkmark.circle", count: completedTasks.count)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 10)
                                    
                                    taskGroup(tasks: completedTasks)
                                }
                                
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
            .navigationTitle("Tasks")
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
            .sheet(isPresented: $isShowingNewTaskSheet) {
                NewTaskView()
            }
            .onAppear {
                // Setup notification observer for FAB
                setupNotificationObserver()
            }
            .onDisappear {
                // Remove notification observer
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowNewTaskSheet"),
            object: nil,
            queue: .main
        ) { _ in
            isShowingNewTaskSheet = true
        }
    }
    
    // MARK: - Views
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search tasks...", text: $searchText)
                .padding(10)
            
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
    
    private func noTasksMessage(message: String) -> some View {
        Text(message)
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    private func taskGroup(tasks: [Task]) -> some View {
        VStack(spacing: 12) {
            ForEach(tasks, id: \.id) { task in
                TaskRow(task: task)
                    .contextMenu {
                        Button(action: {
                            toggleTaskCompletion(task)
                        }) {
                            Label(task.completed ? "Mark Incomplete" : "Mark Complete", 
                                  systemImage: task.completed ? "xmark.circle" : "checkmark.circle")
                        }
                        
                        Button(role: .destructive, action: {
                            deleteTask(task)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(Color(hex: "5E6BE8").opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "checklist")
                    .font(.system(size: 80))
                    .foregroundColor(Color(hex: "5E6BE8"))
            }
            .padding(.bottom, 20)
            
            // Text
            Text("No Tasks Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
            
            Text("Start adding tasks to track your progress and stay organized.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Button
            Button(action: {
                isShowingNewTaskSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create New Task")
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
    
    // MARK: - Filtered Tasks
    
    private var filteredTasks: [Task] {
        if searchText.isEmpty {
            return Array(tasks)
        } else {
            return tasks.filter {
                ($0.title?.lowercased().contains(searchText.lowercased()) ?? false) ||
                ($0.details?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    
    private var pendingTasks: [Task] {
        filteredTasks.filter { !$0.completed }
    }
    
    private var completedTasks: [Task] {
        filteredTasks.filter { $0.completed }
    }
    
    private var todayTasks: [Task] {
        pendingTasks.filter { task in
            if let dueDate = task.dueDate {
                return Calendar.current.isDateInToday(dueDate)
            }
            return false
        }
    }
    
    private var upcomingTasks: [Task] {
        pendingTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !Calendar.current.isDateInToday(dueDate)
        }
    }
    
    // MARK: - Actions
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            task.completed.toggle()
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteTask(_ task: Task) {
        withAnimation {
            viewContext.delete(task)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isPressed = false
    @State private var isShowingEditSheet = false
    @State private var isShowingDatePicker = false
    @State private var isShowingPriorityPicker = false
    @State private var editingDate = Date()
    
    // Color gradients for priority levels
    private var priorityGradient: LinearGradient {
        switch task.priority {
        case 0:
            return LinearGradient(
                gradient: Gradient(colors: [Color(hex: "4F7FFA"), Color(hex: "335CD7")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 1:
            return LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FF9D42"), Color(hex: "FF8800")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FF5D5D"), Color(hex: "FF3B30")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color(hex: "4F7FFA"), Color(hex: "335CD7")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        taskRowContent
            .onTapGesture {
                withAnimation {
                    isPressed = true
                }
                
                // Small delay to show the press animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        isPressed = false
                    }
                    toggleCompletion()
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                EditTaskView(task: task)
            }
            .sheet(isPresented: $isShowingDatePicker) {
                DatePickerSheet(date: $editingDate, isPresented: $isShowingDatePicker) { newDate in
                    updateDueDate(newDate)
                }
                .presentationDetents([.height(420)])
            }
            .sheet(isPresented: $isShowingPriorityPicker) {
                PriorityPickerSheet(priority: task.priority, isPresented: $isShowingPriorityPicker) { newPriority in
                    updatePriority(newPriority)
                }
                .presentationDetents([.height(220)])
            }
    }
    
    // MARK: - Component Views
    
    private var taskRowContent: some View {
        ZStack(alignment: .leading) {
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? 
                      Color(hex: task.completed ? "2A2A2A" : "343434") : 
                      Color(hex: task.completed ? "F5F5F5" : "FFFFFF"))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                        radius: 8, x: 0, y: 4)
            
            // Vertical accent line showing priority
            Rectangle()
                .fill(priorityGradient)
                .frame(width: 4)
                .cornerRadius(2)
                .padding(.vertical, 12)
                .padding(.leading, 12)
            
            // Task content
            HStack(spacing: 16) {
                // Checkbox
                Button(action: {
                    toggleCompletion()
                }) {
                    ZStack {
                        Circle()
                            .stroke(
                                task.completed ? Color.green : Color.gray.opacity(0.5),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)
                        
                        if task.completed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
                
                // Task details
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title ?? "Untitled Task")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(task.completed ? .secondary : (colorScheme == .dark ? .white : .black))
                        .strikethrough(task.completed)
                        .lineLimit(1)
                    
                    if let details = task.details, !details.isEmpty {
                        Text(details)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .opacity(task.completed ? 0.7 : 1.0)
                    }
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        if let dueDate = task.dueDate {
                            // Tappable date tag
                            Button(action: {
                                editingDate = dueDate
                                isShowingDatePicker = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 12))
                                    Text(dueDate.formattedDate())
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(getDueDateColor(dueDate))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(getDueDateColor(dueDate).opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        // Tappable priority tag
                        Button(action: {
                            isShowingPriorityPicker = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 12))
                                Text(task.priorityName)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(task.priorityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(task.priorityColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: {
                    isShowingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.completed)
    }
    
    // MARK: - Helper Functions
    
    private func getDueDateColor(_ date: Date) -> Color {
        if date.isPast && !task.completed {
            return Color(hex: "FF3B30") // red
        } else if date.isToday {
            return Color(hex: "FF9500") // orange
        } else {
            return Color(hex: "34C759") // green
        }
    }
    
    private func toggleCompletion() {
        withAnimation {
            task.completed.toggle()
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error toggling completion: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func updateDueDate(_ date: Date) {
        task.dueDate = date
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error updating due date: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func updatePriority(_ level: Int16) {
        task.priority = level
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error updating priority: \(nsError), \(nsError.userInfo)")
        }
    }
}

// Edit Task View - Uses the same form as NewTaskView but prefills with existing data
struct EditTaskView: View {
    let task: Task
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var title: String
    @State private var details: String
    @State private var dueDate: Date
    @State private var priority: Int16
    @State private var isShowingDatePicker: Bool
    @State private var selectedColor: String // Default color
    
    init(task: Task) {
        self.task = task
        // Initialize state variables with task data
        _title = State(initialValue: task.title ?? "")
        _details = State(initialValue: task.details ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _priority = State(initialValue: task.priority)
        _isShowingDatePicker = State(initialValue: task.dueDate != nil)
        _selectedColor = State(initialValue: "5E6BE8") // Default color
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
                VStack(spacing: 24) {
                    // Task title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TITLE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextField("Task title", text: $title)
                            .font(.system(size: 17))
                            .padding()
                            .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    // Task details input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DETAILS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            if details.isEmpty {
                                Text("Add task details (optional)")
                                    .foregroundColor(Color.gray.opacity(0.7))
                                    .font(.system(size: 17))
                                    .padding(.top, 18)
                                    .padding(.leading, 16)
                            }
                            
                            TextEditor(text: $details)
                                .font(.system(size: 17))
                                .padding(4)
                                .frame(minHeight: 120)
                                .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    // Due date section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("DUE DATE")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $isShowingDatePicker)
                                .labelsHidden()
                                .tint(Color(hex: selectedColor))
                        }
                        
                        if isShowingDatePicker {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(Color(hex: selectedColor))
                                
                                DatePicker("Select date", selection: $dueDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                
                                Spacer()
                                
                                Text(dueDate.formattedDate())
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    // Priority section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRIORITY")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            priorityButton(level: 0, label: "Low")
                            priorityButton(level: 1, label: "Medium")
                            priorityButton(level: 2, label: "High")
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Save button
                    Button(action: {
                        updateTask()
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 54)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(title.isEmpty ? Color.gray.opacity(0.5) : Color(hex: selectedColor))
                                    .shadow(color: title.isEmpty ? Color.clear : Color(hex: selectedColor).opacity(0.4), 
                                            radius: 8, x: 0, y: 4)
                            )
                    }
                    .disabled(title.isEmpty)
                    .padding(.bottom, 30)
                }
                .padding(24)
            }
        }
        .navigationTitle("Edit Task")
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
    
    private func priorityButton(level: Int16, label: String) -> some View {
        Button(action: {
            priority = level
        }) {
            Text(label)
                .font(.system(size: 15, weight: priority == level ? .semibold : .regular))
                .foregroundColor(priority == level ? .white : (colorScheme == .dark ? .white : Color(hex: "2D3142")))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(priority == level ? Color(hex: selectedColor) : 
                              (colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white.opacity(0.8)))
                        .shadow(color: priority == level ? Color(hex: selectedColor).opacity(0.3) : Color.black.opacity(0.03), 
                                radius: 5, x: 0, y: 2)
                )
        }
    }
    
    private func updateTask() {
        task.title = title
        task.details = details
        task.dueDate = isShowingDatePicker ? dueDate : nil
        task.priority = priority
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error updating task: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct NewTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var title = ""
    @State private var details = ""
    @State private var dueDate = Date()
    @State private var priority: Int16 = 0
    @State private var isShowingDatePicker = false
    @State private var selectedColor = "5E6BE8" // Default color
    
    // Color options for tasks
    private let colorOptions = [
        "5E6BE8", // Primary blue
        "FF9D42", // Orange
        "4CD964", // Green
        "FF3B30", // Red
        "AF52DE", // Purple
        "FF2D55"  // Pink
    ]
    
    var body: some View {
        NavigationView {
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
                        // Task title input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("Task title", text: $title)
                                .font(.system(size: 17))
                                .padding()
                                .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Task details input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DETAILS")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if details.isEmpty {
                                    Text("Add task details (optional)")
                                        .foregroundColor(Color.gray.opacity(0.7))
                                        .font(.system(size: 17))
                                        .padding(.top, 18)
                                        .padding(.leading, 16)
                                }
                                
                                TextEditor(text: $details)
                                    .font(.system(size: 17))
                                    .padding(4)
                                    .frame(minHeight: 120)
                                    .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        // Due date section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("DUE DATE")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isShowingDatePicker)
                                    .labelsHidden()
                                    .tint(Color(hex: selectedColor))
                            }
                            
                            if isShowingDatePicker {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color(hex: selectedColor))
                                    
                                    DatePicker("Select date", selection: $dueDate, displayedComponents: [.date])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                    
                                    Spacer()
                                    
                                    Text(dueDate.formattedDate())
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        // Priority section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIORITY")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                priorityButton(level: 0, label: "Low")
                                priorityButton(level: 1, label: "Medium")
                                priorityButton(level: 2, label: "High")
                            }
                        }
                        
                        // Color selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("COLOR")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                                .padding(2)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: color).opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: Color(hex: color).opacity(0.5), radius: 3, x: 0, y: 0)
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: selectedColor))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(title.isEmpty ? Color.gray : Color(hex: selectedColor))
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func priorityButton(level: Int16, label: String) -> some View {
        Button(action: {
            priority = level
        }) {
            Text(label)
                .font(.system(size: 15, weight: priority == level ? .semibold : .regular))
                .foregroundColor(priority == level ? .white : (colorScheme == .dark ? .white : Color(hex: "2D3142")))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(priority == level ? Color(hex: selectedColor) : 
                              (colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white.opacity(0.8)))
                        .shadow(color: priority == level ? Color(hex: selectedColor).opacity(0.3) : Color.black.opacity(0.03), 
                                radius: 5, x: 0, y: 2)
                )
        }
    }
    
    private func saveTask() {
        let newTask = Task(context: viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.details = details
        newTask.dueDate = isShowingDatePicker ? dueDate : nil
        newTask.priority = priority
        newTask.completed = false
        newTask.createdAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving task: \(nsError), \(nsError.userInfo)")
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    var onSave: (Date) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .onChange(of: date) { oldValue, newValue in
                    onSave(newValue)
                }
            }
            .navigationTitle("Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "5E6BE8"))
                }
            }
            .background(
                colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F9FF")
            )
        }
    }
}

// MARK: - Priority Picker Sheet

struct PriorityPickerSheet: View {
    let currentPriority: Int16
    @Binding var isPresented: Bool
    var onSelect: (Int16) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(priority: Int16, isPresented: Binding<Bool>, onSelect: @escaping (Int16) -> Void) {
        self.currentPriority = priority
        self._isPresented = isPresented
        self.onSelect = onSelect
    }
    
    var body: some View {
        NavigationView {
            List {
                priorityOption(level: 0, title: "Low", color: Color(hex: "4F7FFA"))
                priorityOption(level: 1, title: "Medium", color: Color(hex: "FF9D42"))
                priorityOption(level: 2, title: "High", color: Color(hex: "FF3B30"))
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "5E6BE8"))
                }
            }
            .background(
                colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F9FF")
            )
        }
    }
    
    private func priorityOption(level: Int16, title: String, color: Color) -> some View {
        Button(action: {
            onSelect(level)
            isPresented = false
        }) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(color)
                
                Text(title)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
                
                if currentPriority == level {
                    Image(systemName: "checkmark")
                        .foregroundColor(color)
                }
            }
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    TaskView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 