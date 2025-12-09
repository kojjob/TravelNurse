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
/// Home, Services, Activities, Account
struct MainTabView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .home

    enum Tab: Int, CaseIterable {
        case home = 0
        case services = 1
        case activities = 2
        case account = 3

        var title: String {
            switch self {
            case .home: return "Home"
            case .services: return "Services"
            case .activities: return "Activities"
            case .account: return "Account"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .services: return "square.grid.2x2.fill"
            case .activities: return "clock.fill"
            case .account: return "person.circle.fill"
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

            ServicesView()
                .tabItem {
                    Label(Tab.services.title, systemImage: Tab.services.icon)
                }
                .tag(Tab.services)

            ActivitiesView()
                .tabItem {
                    Label(Tab.activities.title, systemImage: Tab.activities.icon)
                }
                .tag(Tab.activities)

            AccountView()
                .tabItem {
                    Label(Tab.account.title, systemImage: Tab.account.icon)
                }
                .tag(Tab.account)
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
