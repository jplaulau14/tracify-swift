//
//  ContentView.swift
//  tracify
//
//  Created by Pats Laurel on 3/7/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ModernTabContainerView(selection: $selectedTab) {
                TaskView()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    .tag(0)
                
                HabitView()
                    .environment(\.managedObjectContext, viewContext)
                    .tabItem {
                        Label("Habits", systemImage: "heart.text.square")
                    }
                    .tag(1)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .tag(2)
            }
            
            // Floating action button overlay - shared across tabs
            if selectedTab == 0 || selectedTab == 1 {
                floatingActionButton
            }
        }
    }
    
    // Shared floating action button
    private var floatingActionButton: some View {
        Button(action: {
            // Different action based on the selected tab
            if selectedTab == 0 {
                // Show new task sheet - TaskView will observe this notification
                NotificationCenter.default.post(name: Notification.Name("ShowNewTaskSheet"), object: nil)
            } else if selectedTab == 1 {
                // Show new habit sheet - HabitView will observe this notification
                NotificationCenter.default.post(name: Notification.Name("ShowNewHabitSheet"), object: nil)
            }
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "5E6BE8"), Color(hex: "6D79FF")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: Color(hex: "5E6BE8").opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 90) // Consistent bottom padding above tab bar
        .zIndex(1)
    }
}

struct ModernTabContainerView<Content: View>: View {
    @Binding var selection: Int
    @Environment(\.colorScheme) private var colorScheme
    let content: Content
    @State private var tabBarHeight: CGFloat = 49 // Default tab bar height
    @State private var bounceOffset = CGSize.zero
    
    init(selection: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            TabView(selection: $selection) {
                content
            }
            .onChange(of: selection) { oldValue, newValue in
                withAnimation(.spring()) {
                    bounceOffset = CGSize(width: 0, height: -10)
                }
                
                withAnimation(.spring().delay(0.1)) {
                    bounceOffset = .zero
                }
            }
            
            // Custom tab bar background
            VStack(spacing: 0) {
                Divider()
                    .opacity(colorScheme == .dark ? 0.15 : 0.1)
                    .padding(.bottom, -1)
                
                HStack {
                    customTabItem(index: 0, icon: "checklist", label: "Tasks")
                    customTabItem(index: 1, icon: "heart.text.square", label: "Habits")
                    customTabItem(index: 2, icon: "person.circle", label: "Profile")
                }
                .padding(.top, 10)
                .padding(.bottom, 30) // Add extra padding for safe area
                .background(
                    RoundedRectangle(cornerRadius: 0) // Tab bar background
                        .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: -4)
                )
            }
            .offset(bounceOffset)
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func customTabItem(index: Int, icon: String, label: String) -> some View {
        let isSelected = selection == index
        
        return Button(action: {
            if selection != index {
                selection = index
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "5E6BE8").opacity(0.1))
                            .frame(width: 48, height: 48)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 20 : 18))
                        .foregroundColor(isSelected ? Color(hex: "5E6BE8") : 
                                          (colorScheme == .dark ? Color.gray : Color(hex: "8E8E93")))
                }
                
                Text(label)
                    .font(.system(size: 11))
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? Color(hex: "5E6BE8") : 
                                      (colorScheme == .dark ? Color.gray : Color(hex: "8E8E93")))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func configureTabBarAppearance() {
        // Hide the original tab bar but keep its functionality
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "6D79FF"), Color(hex: "5E6BE8")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 110, height: 110)
                                .shadow(color: Color(hex: "5E6BE8").opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 30)
                        
                        Text("Welcome to Tracify")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                        
                        Text("Your personal habit and task tracker")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
                    
                    // Settings sections
                    VStack(spacing: 16) {
                        modernInfoSection(title: "App Settings", items: [
                            InfoItem(icon: "gear", title: "Settings", subtitle: "App preferences and notifications"),
                            InfoItem(icon: "moon.fill", title: "Appearance", subtitle: "Dark and light mode settings")
                        ])
                        
                        modernInfoSection(title: "Data", items: [
                            InfoItem(icon: "arrow.up.arrow.down", title: "Sync", subtitle: "Last synced: Today, 2:30 PM"),
                            InfoItem(icon: "externaldrive.fill.badge.icloud", title: "Backup", subtitle: "Automatic cloud backup")
                        ])
                        
                        modernInfoSection(title: "Support", items: [
                            InfoItem(icon: "questionmark.circle", title: "Help & Support", subtitle: "FAQs and contact options"),
                            InfoItem(icon: "info.circle", title: "About", subtitle: "Version 1.0.0")
                        ])
                    }
                    .padding(.horizontal)
                    
                    // Add bottom padding to ensure content doesn't overlap with tab bar
                    Color.clear.frame(height: 50)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F8F9FF"),
                        colorScheme == .dark ? Color(hex: "212121") : Color(hex: "FFFFFF")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func modernInfoSection(title: String, items: [InfoItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                .padding(.horizontal, 8)
            
            VStack(spacing: 12) {
                ForEach(items, id: \.title) { item in
                    ModernInfoRow(item: item)
                }
            }
        }
    }
}

struct InfoItem {
    let icon: String
    let title: String
    let subtitle: String
}

struct ModernInfoRow: View {
    let item: InfoItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "5E6BE8").opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "5E6BE8"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2D3142"))
                
                Text(item.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), 
                        radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
