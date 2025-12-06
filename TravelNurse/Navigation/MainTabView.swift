//
//  MainTabView.swift
//  TravelNurse
//
//  Main navigation container with 4-tab layout
//

import SwiftUI
import SwiftData

/// Main navigation container for the app
/// Manages tab-based navigation with 4 primary tabs:
/// Home, Taxes, Reports, Settings
struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home = 0
        case assignments = 1
        case expenses = 2
        case taxHome = 3
        case reports = 4

        var title: String {
            switch self {
            case .home: return "Home"
            case .assignments: return "Assignments"
            case .expenses: return "Expenses"
            case .taxHome: return "Tax Home"
            case .reports: return "Reports"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .assignments: return "briefcase.fill"
            case .expenses: return "creditcard.fill"
            case .taxHome: return "mappin.and.ellipse"
            case .reports: return "chart.bar.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            AssignmentListView()
                .tabItem {
                    Label(Tab.taxes.title, systemImage: Tab.taxes.icon)
                }
                .tag(Tab.taxes)

            ExpenseListView()
                .tabItem {
                    Label(Tab.expenses.title, systemImage: Tab.expenses.icon)
                }
                .tag(Tab.expenses)

            TaxHomeView()
                .tabItem {
                    Label(Tab.taxHome.title, systemImage: Tab.taxHome.icon)
                }
                .tag(Tab.reports)

            ReportsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(TNColors.primary)
        .onAppear {
            configureServices()
            configureTabBarAppearance()
        }
    }

    private func configureServices() {
        // Configure ServiceContainer if not already configured
        if ServiceContainer.shared.modelContext == nil {
            ServiceContainer.shared.configure(with: modelContext)
        }
    }

struct ExpensesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming Soon",
                systemImage: "creditcard.fill",
                description: Text("Expense tracking will be available in the next update.")
            )
            .navigationTitle("Expenses")
        }
    }
}

// TaxHomePlaceholderView removed - using TaxHomeView instead

// ReportsPlaceholderView removed - using ReportsView from Sprint 7

#Preview {
    MainTabView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
