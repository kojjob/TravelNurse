//
//  HomeView.swift
//  TravelNurse
//
//  Redesigned home screen matching the modern mockup design
//

import SwiftUI
import SwiftData

/// Main home view with tax due card, assignment progress, and activity feed
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Greeting Header
                    greetingHeader

                    // Estimated Tax Due Card
                    taxDueCard

                    // Quick Action Buttons
                    quickActionButtons

                    // Current Assignment Section
                    currentAssignmentSection

                    // States Worked Section
                    statesWorkedSection

                    // Recent Activity Section
                    recentActivitySection
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingAddIncome) {
                AddIncomeSheet()
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseSheet()
            }
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(viewModel.greetingText)
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(TNColors.textSecondary)

                HStack(spacing: TNSpacing.xs) {
                    Text(viewModel.userName)
                        .font(TNTypography.displaySmall)
                        .foregroundColor(TNColors.textPrimary)

                    Text("👋")
                        .font(.system(size: 28))
                }
            }

            Spacer()
        }
        .padding(.top, TNSpacing.sm)
    }

    // MARK: - Tax Due Card

    private var taxDueCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Estimated \(viewModel.currentQuarter) Tax Due")
                .font(TNTypography.bodyMedium)
                .foregroundColor(.white.opacity(0.9))

            Text(viewModel.formattedEstimatedTaxDue)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Due \(viewModel.formattedTaxDueDate)")
                .font(TNTypography.bodySmall)
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: TNSpacing.lg) {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("YTD Income")
                        .font(TNTypography.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(viewModel.formattedYTDIncome)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.vertical, TNSpacing.sm)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))

                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("YTD Deductions")
                        .font(TNTypography.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Text(viewModel.formattedYTDDeductions)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.vertical, TNSpacing.sm)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.lg)
        .background(
            LinearGradient(
                colors: [TNColors.primary, TNColors.primaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
    }

    // MARK: - Quick Action Buttons

    private var quickActionButtons: some View {
        HStack(spacing: TNSpacing.md) {
            HomeQuickActionButton(
                title: "Add Income",
                icon: "plus",
                color: TNColors.primary
            ) {
                showingAddIncome = true
            }

            HomeQuickActionButton(
                title: "Add Expense",
                icon: "plus",
                color: TNColors.error
            ) {
                showingAddExpense = true
            }
        }
    }

    // MARK: - Current Assignment Section

    private var currentAssignmentSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("CURRENT ASSIGNMENT")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            if let assignment = viewModel.currentAssignment {
                CurrentAssignmentCard(
                    assignment: assignment,
                    weekNumber: viewModel.currentWeekNumber,
                    totalWeeks: viewModel.totalWeeks,
                    weeklyRate: viewModel.formattedWeeklyRate,
                    progress: viewModel.assignmentProgress
                )
            } else {
                NoAssignmentCard()
            }
        }
    }

    // MARK: - States Worked Section

    private var statesWorkedSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("\(viewModel.currentYear) STATES WORKED")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            if viewModel.statesWorked.isEmpty {
                Text("No states tracked yet")
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(TNColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(TNSpacing.lg)
                    .background(TNColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TNSpacing.sm) {
                        ForEach(viewModel.statesWorked, id: \.state) { stateData in
                            StateIncomeChip(
                                stateCode: stateData.state.rawValue,
                                income: stateData.formattedIncome,
                                isTaxable: !stateData.state.hasNoIncomeTax
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("RECENT ACTIVITY")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                if viewModel.recentActivities.isEmpty {
                    VStack(spacing: TNSpacing.sm) {
                        Image(systemName: "clock")
                            .font(.system(size: 32))
                            .foregroundColor(TNColors.textTertiary)

                        Text("No recent activity")
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(TNSpacing.xl)
                } else {
                    ForEach(viewModel.recentActivities) { activity in
                        HomeActivityRow(activity: activity)

                        if activity.id != viewModel.recentActivities.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Supporting Components

struct HomeQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: TNSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(title)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct CurrentAssignmentCard: View {
    let assignment: Assignment
    let weekNumber: Int
    let totalWeeks: Int
    let weeklyRate: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(assignment.facilityName)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(TNColors.textPrimary)

                    Text(assignment.location?.cityState ?? "Location TBD")
                        .font(TNTypography.bodySmall)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                StatusBadge(status: assignment.status)
            }

            HStack {
                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.textSecondary)

                    Text("Week \(weekNumber) of \(totalWeeks)")
                        .font(TNTypography.bodySmall)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                HStack(spacing: TNSpacing.xs) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.textSecondary)

                    Text(weeklyRate)
                        .font(TNTypography.bodySmall)
                        .foregroundColor(TNColors.textSecondary)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.border)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.primary)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
    }
}

struct NoAssignmentCard: View {
    var body: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "briefcase")
                .font(.system(size: 36))
                .foregroundColor(TNColors.textTertiary)

            Text("No Active Assignment")
                .font(TNTypography.titleMedium)
                .foregroundColor(TNColors.textSecondary)

            Text("Add an assignment to track your progress")
                .font(TNTypography.bodySmall)
                .foregroundColor(TNColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.xl)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
    }
}

struct StatusBadge: View {
    let status: AssignmentStatus

    var body: some View {
        Text(status.displayName)
            .font(TNTypography.labelSmall)
            .foregroundColor(status.color)
            .padding(.horizontal, TNSpacing.sm)
            .padding(.vertical, TNSpacing.xxs)
            .background(status.color.opacity(0.1))
            .clipShape(Capsule())
    }
}

struct StateIncomeChip: View {
    let stateCode: String
    let income: String
    let isTaxable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.xs) {
            HStack(spacing: TNSpacing.xs) {
                Text(stateCode)
                    .font(TNTypography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, TNSpacing.xs)
                    .padding(.vertical, 2)
                    .background(TNColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(income)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)
            }

            Text(isTaxable ? "Taxable" : "No State Tax")
                .font(.system(size: 10))
                .foregroundColor(isTaxable ? TNColors.textSecondary : TNColors.success)
        }
        .padding(TNSpacing.sm)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
    }
}

struct HomeActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.iconBackgroundColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(activity.iconBackgroundColor)
            }

            // Details
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(activity.title)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                Text(activity.subtitle)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            // Amount and Badge
            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(activity.formattedAmount)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(activity.amountColor)

                if let badge = activity.badge {
                    Text(badge)
                        .font(.system(size: 10))
                        .foregroundColor(TNColors.success)
                        .padding(.horizontal, TNSpacing.xs)
                        .padding(.vertical, 2)
                        .background(TNColors.success.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(TNSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [
            Assignment.self,
            UserProfile.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
