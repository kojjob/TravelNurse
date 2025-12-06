//
//  MainTabView.swift
//  TravelNurse
//
//  Main navigation container with tab-based navigation
//

import SwiftUI
import SwiftData

/// Main navigation container for the app
/// Manages tab-based navigation and service injection
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
            DashboardView()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            AssignmentListView()
                .tabItem {
                    Label(Tab.assignments.title, systemImage: Tab.assignments.icon)
                }
                .tag(Tab.assignments)

            ExpenseListView()
                .tabItem {
                    Label(Tab.expenses.title, systemImage: Tab.expenses.icon)
                }
                .tag(Tab.expenses)

            TaxHomeView()
                .tabItem {
                    Label(Tab.taxHome.title, systemImage: Tab.taxHome.icon)
                }
                .tag(Tab.taxHome)

            ReportsView()
                .tabItem {
                    Label(Tab.reports.title, systemImage: Tab.reports.icon)
                }
                .tag(Tab.reports)
        }
        .tint(TNColors.primary)
        .onAppear {
            configureServices()
        }
    }

    private func configureServices() {
        // Configure ServiceContainer if not already configured
        if ServiceContainer.shared.modelContext == nil {
            ServiceContainer.shared.configure(with: modelContext)
        }
    }
}

// MARK: - Placeholder Views (to be replaced in later sprints)

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

struct ReportsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming Soon",
                systemImage: "chart.bar.fill",
                description: Text("Tax reports and exports will be available in the next update.")
            )
            .navigationTitle("Reports")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            Assignment.self,
            UserProfile.self,
            Address.self,
            PayBreakdown.self,
            Expense.self,
            Receipt.self,
            MileageTrip.self,
            TaxHomeCompliance.self,
            Document.self
        ], inMemory: true)
}
