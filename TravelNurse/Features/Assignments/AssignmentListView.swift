//
//  AssignmentListView.swift
//  TravelNurse
//
//  Main list view for assignments with consistent card-based design
//

import SwiftUI
import SwiftData

/// Main view displaying all assignments with summary metrics
struct AssignmentListView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AssignmentViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.assignments.isEmpty {
                        emptyStateView
                    } else {
                        // Summary Metrics
                        metricsSection

                        // Active Assignment (if any)
                        if let activeAssignment = viewModel.filteredAssignments.first(where: { $0.status == .active }) {
                            activeAssignmentSection(activeAssignment)
                        }

                        // Filter Pills
                        filterSection

                        // Assignment List
                        assignmentsSection
                    }
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.loadAssignments()
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddAssignmentView { newAssignment in
                    viewModel.addAssignment(newAssignment)
                    viewModel.refresh()
                }
            }
            .sheet(item: $viewModel.selectedAssignment) { assignment in
                AssignmentDetailView(
                    assignment: assignment,
                    onUpdate: { updatedAssignment in
                        viewModel.updateAssignment(updatedAssignment)
                        viewModel.refresh()
                    },
                    onDelete: {
                        viewModel.deleteAssignment(assignment)
                        viewModel.refresh()
                    }
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: TNSpacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading assignments...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: TNSpacing.md) {
            Image(systemName: "briefcase")
                .font(.system(size: 48))
                .foregroundStyle(TNColors.textTertiary)

            Text("No Assignments Yet")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            Text("Start tracking your travel nursing assignments to manage contracts and monitor earnings.")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.lg)

            Button {
                viewModel.showingAddSheet = true
            } label: {
                Text("Add Assignment")
                    .font(TNTypography.buttonMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(TNColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.xl)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: TNSpacing.sm) {
            AssignmentMetricCard(
                value: "\(viewModel.activeAssignmentsCount)",
                label: "Active",
                icon: "bolt.fill",
                color: TNColors.success
            )

            AssignmentMetricCard(
                value: "\(viewModel.totalAssignments)",
                label: "Total",
                icon: "briefcase.fill",
                color: TNColors.primary
            )

            AssignmentMetricCard(
                value: formattedTotalEarnings,
                label: "Earned",
                icon: "dollarsign.circle.fill",
                color: TNColors.accent
            )
        }
    }

    private var formattedTotalEarnings: String {
        let total = viewModel.filteredAssignments.reduce(Decimal.zero) { sum, assignment in
            sum + (assignment.payBreakdown?.weeklyGross ?? 0) * Decimal(assignment.durationWeeks)
        }
        if total >= 1000 {
            let thousands = NSDecimalNumber(decimal: total / 1000).doubleValue
            return String(format: "$%.0fK", thousands)
        }
        return "$\(total)"
    }

    // MARK: - Active Assignment Section

    private func activeAssignmentSection(_ assignment: Assignment) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Current Assignment")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            ActiveAssignmentCard(assignment: assignment) {
                viewModel.selectAssignment(assignment)
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(AssignmentFilterStatus.allCases) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: viewModel.filterStatus == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.filterStatus = filter
                        }
                    }
                }
            }
        }
    }

    // MARK: - Assignments Section

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            ForEach(viewModel.assignmentYears, id: \.self) { year in
                VStack(alignment: .leading, spacing: TNSpacing.sm) {
                    HStack {
                        Text(String(year))
                            .font(TNTypography.headlineMedium)
                            .foregroundStyle(TNColors.textPrimary)

                        Spacer()

                        Text("\(viewModel.assignments(forYear: year).count) assignments")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    }

                    VStack(spacing: TNSpacing.sm) {
                        ForEach(viewModel.assignments(forYear: year)) { assignment in
                            AssignmentCard(assignment: assignment) {
                                viewModel.selectAssignment(assignment)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func countForFilter(_ filter: AssignmentFilterStatus) -> Int? {
        switch filter {
        case .all:
            return viewModel.totalAssignments > 0 ? viewModel.totalAssignments : nil
        case .active:
            return viewModel.activeAssignmentsCount > 0 ? viewModel.activeAssignmentsCount : nil
        case .upcoming:
            return viewModel.upcomingAssignmentsCount > 0 ? viewModel.upcomingAssignmentsCount : nil
        case .completed:
            return viewModel.completedAssignmentsCount > 0 ? viewModel.completedAssignmentsCount : nil
        case .cancelled:
            return nil
        }
    }
}

// MARK: - Assignment Metric Card

struct AssignmentMetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: TNSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(TNTypography.titleLarge)
                .foregroundStyle(TNColors.textPrimary)

            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Active Assignment Card

struct ActiveAssignmentCard: View {
    let assignment: Assignment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: TNSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        Text(assignment.facilityName)
                            .font(TNTypography.headlineSmall)
                            .foregroundStyle(TNColors.textPrimary)

                        if let location = assignment.location?.cityState {
                            HStack(spacing: TNSpacing.xxs) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text(location)
                            }
                            .font(TNTypography.bodySmall)
                            .foregroundStyle(TNColors.textSecondary)
                        }
                    }

                    Spacer()

                    AssignmentStatusBadge(status: .active)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        Text("Days Remaining")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)

                        Text("\(assignment.daysRemaining ?? 0)")
                            .font(TNTypography.displaySmall)
                            .foregroundStyle(TNColors.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                        Text("Progress")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)

                        Text("\(Int(assignment.progressPercentage))%")
                            .font(TNTypography.displaySmall)
                            .foregroundStyle(TNColors.success)
                    }
                }

                ProgressView(value: assignment.progressPercentage / 100)
                    .tint(TNColors.primary)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Assignment Card

struct AssignmentCard: View {
    let assignment: Assignment
    let onTap: () -> Void

    private var formattedPay: String {
        guard let pay = assignment.payBreakdown?.weeklyGross else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return "\(formatter.string(from: pay as NSDecimalNumber) ?? "$0")/wk"
    }

    private var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: assignment.startDate)) - \(formatter.string(from: assignment.endDate))"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: TNSpacing.md) {
                // Status indicator
                Circle()
                    .fill(assignment.status.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(assignment.facilityName)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: TNSpacing.xs) {
                        if let location = assignment.location?.cityState {
                            Text(location)
                        }
                        Text("•")
                        Text(dateRange)
                    }
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                    Text(formattedPay)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.success)

                    Text("\(assignment.durationWeeks) weeks")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TNColors.textTertiary)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TNSpacing.xxs) {
                Text(title)
                    .font(TNTypography.labelMedium)

                if let count = count {
                    Text("\(count)")
                        .font(TNTypography.labelSmall)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white.opacity(0.2) : TNColors.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? .white : TNColors.textPrimary)
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.sm)
            .background(isSelected ? TNColors.primary : TNColors.surface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AssignmentListView()
        .modelContainer(for: [
            Assignment.self,
            UserProfile.self,
            Address.self,
            PayBreakdown.self
        ], inMemory: true)
}
