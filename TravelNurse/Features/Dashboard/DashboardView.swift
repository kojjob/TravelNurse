//
//  DashboardView.swift
//  TravelNurse
//
//  Main dashboard view showing key metrics and status
//

import SwiftUI
import SwiftData

/// Main dashboard view with real-time metrics
struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Current Assignment Card
                    currentAssignmentSection

                    // Metrics Grid
                    metricsGridSection

                    // Compliance Status
                    complianceSection

                    // Recent Activity
                    recentActivitySection
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Dashboard")
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.loadData()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
    }

    // MARK: - Current Assignment Section

    @ViewBuilder
    private var currentAssignmentSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Current Assignment")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            if let assignment = viewModel.currentAssignment {
                DashboardAssignmentCard(
                    assignment: assignment,
                    daysRemaining: viewModel.assignmentDaysRemaining ?? 0,
                    progress: viewModel.assignmentProgress
                )
            } else {
                DashboardNoAssignmentCard()
            }
        }
    }

    // MARK: - Metrics Grid Section

    @ViewBuilder
    private var metricsGridSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: TNSpacing.md) {
            DashboardMetricCard(
                title: "YTD Earnings",
                value: viewModel.formattedYTDEarnings,
                icon: "dollarsign.circle.fill",
                color: TNColors.success
            )

            DashboardMetricCard(
                title: "YTD Expenses",
                value: viewModel.formattedYTDExpenses,
                icon: "creditcard.fill",
                color: TNColors.primary
            )

            DashboardMetricCard(
                title: "Miles Tracked",
                value: String(format: "%.0f mi", viewModel.totalMileage),
                icon: "car.fill",
                color: TNColors.accent
            )

            DashboardMetricCard(
                title: "Mileage Deduction",
                value: viewModel.formattedMileageDeduction,
                icon: "leaf.fill",
                color: TNColors.success
            )
        }
    }

    // MARK: - Compliance Section

    @ViewBuilder
    private var complianceSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Tax Home Compliance")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            DashboardComplianceCard(
                score: viewModel.complianceScore,
                level: viewModel.complianceLevel,
                daysUntilVisit: viewModel.daysUntilVisit,
                statusColor: viewModel.complianceStatusColor
            )
        }
    }

    // MARK: - Recent Activity Section

    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Text("Recent Expenses")
                    .font(TNTypography.headlineMedium)
                    .foregroundStyle(TNColors.textPrimary)

                Spacer()

                Button("See All") {
                    // TODO: Navigate to expenses tab
                }
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.primary)
            }

            if viewModel.recentExpenses.isEmpty {
                DashboardEmptyExpensesCard()
            } else {
                VStack(spacing: TNSpacing.xs) {
                    ForEach(viewModel.recentExpenses) { expense in
                        DashboardExpenseRow(expense: expense)
                    }
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }
}

// MARK: - Dashboard Components

/// Card showing current assignment details
struct DashboardAssignmentCard: View {
    let assignment: Assignment
    let daysRemaining: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(assignment.facilityName)
                        .font(TNTypography.headlineSmall)
                        .foregroundStyle(TNColors.textPrimary)

                    Text(assignment.location?.cityState ?? "Location TBD")
                        .font(TNTypography.bodyMedium)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                DashboardStatusBadge(status: assignment.status)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text("Days Remaining")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)

                    Text("\(daysRemaining)")
                        .font(TNTypography.displaySmall)
                        .foregroundStyle(TNColors.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text("Progress")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)

                    Text("\(Int(progress * 100))%")
                        .font(TNTypography.displaySmall)
                        .foregroundStyle(TNColors.success)
                }
            }

            ProgressView(value: progress)
                .tint(TNColors.primary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

/// Card shown when no active assignment
struct DashboardNoAssignmentCard: View {
    var body: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "briefcase")
                .font(.system(size: 40))
                .foregroundStyle(TNColors.textTertiary)

            Text("No Active Assignment")
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textSecondary)

            Text("Add an assignment to start tracking your travel nursing journey.")
                .font(TNTypography.bodySmall)
                .foregroundStyle(TNColors.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                // TODO: Navigate to add assignment
            } label: {
                Text("Add Assignment")
                    .font(TNTypography.buttonMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(TNColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

/// Reusable metric card component
struct DashboardMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)

                Spacer()
            }

            Text(value)
                .font(TNTypography.titleLarge)
                .foregroundStyle(TNColors.textPrimary)

            Text(title)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

/// Compliance status card
struct DashboardComplianceCard: View {
    let score: Int
    let level: ComplianceLevel
    let daysUntilVisit: Int?
    let statusColor: Color

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Score Ring
            ZStack {
                Circle()
                    .stroke(TNColors.border, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(score)")
                        .font(TNTypography.displayMedium)
                        .foregroundStyle(statusColor)

                    Text("%")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                Text(level.displayName)
                    .font(TNTypography.headlineSmall)
                    .foregroundStyle(statusColor)

                if let days = daysUntilVisit {
                    HStack(spacing: TNSpacing.xxs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))

                        Text("\(days) days until required visit")
                            .font(TNTypography.caption)
                    }
                    .foregroundStyle(days < 7 ? TNColors.warning : TNColors.textSecondary)
                }

                Text("Tap to view compliance checklist")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TNColors.textTertiary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

/// Empty state for expenses
struct DashboardEmptyExpensesCard: View {
    var body: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "receipt")
                .font(.system(size: 32))
                .foregroundStyle(TNColors.textTertiary)

            Text("No Recent Expenses")
                .font(TNTypography.titleMedium)
                .foregroundStyle(TNColors.textSecondary)

            Text("Start tracking your deductible expenses")
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

/// Row displaying an expense
struct DashboardExpenseRow: View {
    let expense: Expense

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: expense.amount as NSDecimalNumber) ?? "$0.00"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: expense.date)
    }

    var body: some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: expense.category.iconName)
                .font(.system(size: 20))
                .foregroundStyle(TNColors.primary)
                .frame(width: 32, height: 32)
                .background(TNColors.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(expense.shortDescription)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)

                Text("\(expense.category.displayName) • \(formattedDate)")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()

            Text(formattedAmount)
                .font(TNTypography.titleSmall)
                .foregroundStyle(TNColors.textPrimary)
        }
        .padding(.vertical, TNSpacing.xs)
    }
}

/// Status badge for assignment status
struct DashboardStatusBadge: View {
    let status: AssignmentStatus

    var body: some View {
        Text(status.displayName)
            .font(TNTypography.labelSmall)
            .foregroundStyle(status.color)
            .padding(.horizontal, TNSpacing.sm)
            .padding(.vertical, TNSpacing.xxs)
            .background(status.color.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
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
