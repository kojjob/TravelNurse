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
        case taxes = 1
        case reports = 2
        case settings = 3

        var title: String {
            switch self {
            case .home: return "Home"
            case .taxes: return "Taxes"
            case .reports: return "Reports"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .taxes: return "chart.line.uptrend.xyaxis"
            case .reports: return "doc.text.fill"
            case .settings: return "gearshape.fill"
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

            TaxesView()
                .tabItem {
                    Label(Tab.taxes.title, systemImage: Tab.taxes.icon)
                }
                .tag(Tab.taxes)

            ReportsView()
                .tabItem {
                    Label(Tab.reports.title, systemImage: Tab.reports.icon)
                }
                .tag(Tab.reports)

            SettingsView()
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

    private func configureTabBarAppearance() {
        // Configure tab bar appearance for consistent styling
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
