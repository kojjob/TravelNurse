//
//  ActivitiesView.swift
//  TravelNurse
//
//  Activity feed showing recent expenses, mileage, and assignments
//

import SwiftUI
import SwiftData

/// Activity feed showing recent user activities
struct ActivitiesView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ActivitiesViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    ActivitiesContent(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Activities")
            .onAppear {
                if viewModel == nil {
                    viewModel = ActivitiesViewModel()
                    viewModel?.loadData()
                }
            }
        }
    }
}

/// Content view with viewModel binding
struct ActivitiesContent: View {

    @Bindable var viewModel: ActivitiesViewModel
    @State private var selectedFilter: ActivityFilter = .all

    var body: some View {
        ScrollView {
            VStack(spacing: TNSpacing.lg) {
                // Quick Stats
                statsSection

                // Filter Pills
                filterSection

                // Activity Feed
                activityFeed
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.bottom, TNSpacing.xl)
        }
        .background(TNColors.background)
        .refreshable {
            viewModel.loadData()
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: TNSpacing.sm) {
            HStack {
                Text("This Week")
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                Spacer()
            }

            HStack(spacing: TNSpacing.md) {
                ActivityStatCard(
                    title: "Expenses",
                    value: "\(viewModel.weeklyExpenseCount)",
                    subtitle: viewModel.formattedWeeklyExpenses,
                    icon: "creditcard.fill",
                    color: TNColors.primary
                )

                ActivityStatCard(
                    title: "Trips",
                    value: "\(viewModel.weeklyTripCount)",
                    subtitle: viewModel.formattedWeeklyMiles,
                    icon: "car.fill",
                    color: TNColors.accent
                )
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(ActivityFilter.allCases) { filter in
                    ActivityFilterChip(
                        title: filter.displayName,
                        icon: filter.iconName,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }

    // MARK: - Activity Feed

    private var activityFeed: some View {
        VStack(spacing: TNSpacing.sm) {
            HStack {
                Text("Recent Activity")
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                Spacer()
            }

            let filteredActivities = viewModel.activities.filter { activity in
                switch selectedFilter {
                case .all:
                    return true
                case .expenses:
                    return activity.type == .expense
                case .mileage:
                    return activity.type == .mileage
                case .assignments:
                    return activity.type == .assignment
                }
            }

            if filteredActivities.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: TNSpacing.sm) {
                    ForEach(filteredActivities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: TNSpacing.md) {
            Image(systemName: selectedFilter.iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(TNColors.textTertiary)

            Text("No \(selectedFilter.displayName) Activity")
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textSecondary)

            Text("Start tracking your expenses and mileage to see your activity here.")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, TNSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity Filter

enum ActivityFilter: String, CaseIterable, Identifiable {
    case all
    case expenses
    case mileage
    case assignments

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "All"
        case .expenses: return "Expenses"
        case .mileage: return "Mileage"
        case .assignments: return "Assignments"
        }
    }

    var iconName: String {
        switch self {
        case .all: return "clock.fill"
        case .expenses: return "creditcard.fill"
        case .mileage: return "car.fill"
        case .assignments: return "briefcase.fill"
        }
    }
}

// MARK: - Activity Stat Card

struct ActivityStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)

                Spacer()

                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(TNColors.textPrimary)
            }

            Text(title)
                .font(TNTypography.labelMedium)
                .foregroundColor(TNColors.textSecondary)

            Text(subtitle)
                .font(TNTypography.caption)
                .foregroundColor(color)
        }
        .padding(TNSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Activity Filter Chip

struct ActivityFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? TNColors.primary : TNColors.surface)
            .foregroundColor(isSelected ? .white : TNColors.textPrimary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? .clear : TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: activity.type.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(activity.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(TNColors.textPrimary)
                    .lineLimit(1)

                Text(activity.subtitle)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Amount/Value
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                Text(activity.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(TNColors.textTertiary)
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Activity Item Model

struct ActivityItem: Identifiable {
    let id: UUID
    let type: ActivityType
    let title: String
    let subtitle: String
    let value: String
    let date: Date

    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Activity Type

enum ActivityType: String {
    case expense
    case mileage
    case assignment

    var iconName: String {
        switch self {
        case .expense: return "creditcard.fill"
        case .mileage: return "car.fill"
        case .assignment: return "briefcase.fill"
        }
    }

    var color: Color {
        switch self {
        case .expense: return TNColors.primary
        case .mileage: return TNColors.accent
        case .assignment: return TNColors.secondary
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class ActivitiesViewModel {

    var isLoading = false
    var errorMessage: String?

    private(set) var activities: [ActivityItem] = []
    private(set) var weeklyExpenseCount: Int = 0
    private(set) var weeklyTripCount: Int = 0
    private(set) var weeklyExpenseTotal: Decimal = 0
    private(set) var weeklyMilesTotal: Double = 0

    // MARK: - Services

    private var expenseService: ExpenseService?
    private var mileageService: MileageService?
    private var assignmentService: AssignmentService?

    // MARK: - Computed Properties

    var formattedWeeklyExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: weeklyExpenseTotal as NSDecimalNumber) ?? "$0.00"
    }

    var formattedWeeklyMiles: String {
        String(format: "%.1f mi", weeklyMilesTotal)
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        errorMessage = nil

        configureServices()
        loadActivities()
        loadWeeklyStats()

        isLoading = false
    }

    private func configureServices() {
        do {
            expenseService = try ServiceContainer.shared.getExpenseService()
            mileageService = try ServiceContainer.shared.getMileageService()
            assignmentService = try ServiceContainer.shared.getAssignmentService()
        } catch {
            errorMessage = "Failed to initialize services: \(error.localizedDescription)"
        }
    }

    private func loadActivities() {
        var allActivities: [ActivityItem] = []

        // Load recent expenses
        if let service = expenseService {
            let expenses = service.fetchRecentOrEmpty(limit: 15)
            for expense in expenses {
                allActivities.append(ActivityItem(
                    id: expense.id,
                    type: .expense,
                    title: expense.merchantName ?? expense.category.displayName,
                    subtitle: expense.category.displayName,
                    value: TNFormatters.currency(expense.amount),
                    date: expense.date
                ))
            }
        }

        // Load recent mileage trips
        if let service = mileageService {
            let trips = service.fetchRecentOrEmpty(limit: 15)
            for trip in trips {
                allActivities.append(ActivityItem(
                    id: trip.id,
                    type: .mileage,
                    title: trip.purpose,
                    subtitle: "\(trip.startLocationName) → \(trip.endLocationName)",
                    value: TNFormatters.miles(trip.distanceMiles),
                    date: trip.startTime
                ))
            }
        }

        // Sort by date descending
        activities = allActivities.sorted { $0.date > $1.date }
    }

    private func loadWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        // Weekly expense stats
        if let service = expenseService {
            let recentExpenses = service.fetchRecentOrEmpty(limit: 50)
            let weeklyExpenses = recentExpenses.filter { $0.date >= weekStart }
            weeklyExpenseCount = weeklyExpenses.count
            weeklyExpenseTotal = weeklyExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        }

        // Weekly mileage stats
        if let service = mileageService {
            let recentTrips = service.fetchRecentOrEmpty(limit: 50)
            let weeklyTrips = recentTrips.filter { $0.startTime >= weekStart }
            weeklyTripCount = weeklyTrips.count
            weeklyMilesTotal = weeklyTrips.reduce(0) { $0 + $1.distanceMiles }
        }
    }
}

// MARK: - Preview

#Preview {
    ActivitiesView()
}
