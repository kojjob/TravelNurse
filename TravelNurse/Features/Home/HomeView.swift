//
//  HomeView.swift
//  TravelNurse
//
//  Modern, elegant dashboard home screen
//

import SwiftUI
import SwiftData

/// Main home view with clean, elegant design
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showingAddExpense = false
    @State private var showingMileageLog = false
    @State private var showingTaxHome = false
    @State private var showingReports = false
    @State private var showingAssignmentDetail = false

    // Animation states
    @State private var cardsAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with greeting
                    headerSection

                    // Stats Grid (2x2)
                    statsGrid

                    // Current Assignment Card
                    if viewModel.currentAssignment != nil {
                        assignmentCard
                    }

                    // Quick Actions
                    quickActionsSection

                    // Recent Activity
                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(backgroundGradient)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    cardsAppeared = true
                }
            }
            .sheet(isPresented: $showingAddExpense, onDismiss: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                AddExpenseSheet()
            }
            .sheet(isPresented: $showingMileageLog, onDismiss: {
                Task {
                    await viewModel.refresh()
                }
            }) {
                MileageTrackerView()
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "F8FAFC"),
                Color(hex: "F1F5F9"),
                Color(hex: "E2E8F0").opacity(0.5)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textSecondary)

                Text("Hi, \(viewModel.userName) 👋")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(TNColors.textPrimary)
            }

            Spacer()

            // Profile Avatar
            profileAvatar
        }
        .padding(.top, 16)
    }

    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [TNColors.primary.opacity(0.2), TNColors.accent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)

            Image(systemName: "person.fill")
                .font(.system(size: 20))
                .foregroundColor(TNColors.primary)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            // YTD Income
            StatCard(
                title: "YTD Income",
                value: formatCurrency(viewModel.ytdIncome),
                icon: "arrow.up.right",
                iconColor: .white,
                gradient: [Color(hex: "10B981"), Color(hex: "059669")]
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)

            // Total Deductions
            StatCard(
                title: "Deductions",
                value: formatCurrency(viewModel.ytdDeductions),
                icon: "arrow.down.right",
                iconColor: .white,
                gradient: [Color(hex: "8B5CF6"), Color(hex: "7C3AED")]
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)

            // Quarterly Tax
            StatCard(
                title: "Est. Tax Due",
                value: formatCurrency(viewModel.estimatedTaxDue),
                icon: "calendar",
                iconColor: .white,
                gradient: [Color(hex: "F59E0B"), Color(hex: "D97706")]
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)

            // Miles Tracked
            StatCard(
                title: "Miles YTD",
                value: "\(Int(viewModel.totalMiles))",
                icon: "car.fill",
                iconColor: .white,
                gradient: [Color(hex: "3B82F6"), Color(hex: "2563EB")]
            )
            .opacity(cardsAppeared ? 1 : 0)
            .offset(y: cardsAppeared ? 0 : 20)
        }
    }

    // MARK: - Assignment Card

    private var assignmentCard: some View {
        Button(action: { showingAssignmentDetail = true }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Assignment")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TNColors.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        if let assignment = viewModel.currentAssignment {
                            Text(assignment.facilityName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(TNColors.textPrimary)

                            Text(assignment.location?.cityState ?? "Location TBD")
                                .font(.system(size: 14))
                                .foregroundColor(TNColors.textSecondary)
                        }
                    }

                    Spacer()

                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(TNColors.primary.opacity(0.15), lineWidth: 4)
                            .frame(width: 56, height: 56)

                        Circle()
                            .trim(from: 0, to: viewModel.assignmentProgress)
                            .stroke(TNColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(viewModel.assignmentProgress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(TNColors.primary)
                    }
                }

                // Days remaining bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(viewModel.daysRemaining) days left")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(TNColors.textSecondary)

                        Spacer()

                        Text("of \(viewModel.totalDays) days")
                            .font(.system(size: 13))
                            .foregroundColor(TNColors.textTertiary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(TNColors.primary.opacity(0.15))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(TNColors.primary)
                                .frame(width: geo.size.width * viewModel.assignmentProgress, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(TNColors.textPrimary)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Expense",
                    icon: "plus.circle.fill",
                    color: TNColors.accent
                ) {
                    HapticManager.lightImpact()
                    showingAddExpense = true
                }

                QuickActionButton(
                    title: "Log Mileage",
                    icon: "car.fill",
                    color: TNColors.info
                ) {
                    HapticManager.lightImpact()
                    showingMileageLog = true
                }

                QuickActionButton(
                    title: "Tax Home",
                    icon: "house.fill",
                    color: TNColors.success
                ) {
                    HapticManager.lightImpact()
                    showingTaxHome = true
                }

                QuickActionButton(
                    title: "Reports",
                    icon: "chart.bar.fill",
                    color: TNColors.warning
                ) {
                    HapticManager.lightImpact()
                    showingReports = true
                }
            }
        }
        .opacity(cardsAppeared ? 1 : 0)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                Button("See All") {
                    showingReports = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TNColors.primary)
            }

            VStack(spacing: 0) {
                if viewModel.recentActivities.isEmpty {
                    emptyActivityState
                } else {
                    ForEach(Array(viewModel.recentActivities.enumerated()), id: \.element.id) { index, activity in
                        ActivityRow(activity: activity)

                        if index < viewModel.recentActivities.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        }
        .opacity(cardsAppeared ? 1 : 0)
    }

    private var emptyActivityState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(TNColors.textTertiary)

            Text("No recent activity")
                .font(.system(size: 14))
                .foregroundColor(TNColors.textSecondary)

            Button("Add your first expense") {
                showingAddExpense = true
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(TNColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        TNFormatters.currencyCompact(value)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: gradient[0].opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TNColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activity.iconBackgroundColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(activity.iconBackgroundColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textPrimary)

                Text(activity.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(TNColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(formatCurrency(activity.amount))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(activity.isPositive ? TNColors.success : TNColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        TNFormatters.currency(value)
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
