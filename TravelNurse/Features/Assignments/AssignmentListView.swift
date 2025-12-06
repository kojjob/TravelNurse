//
//  AssignmentListView.swift
//  TravelNurse
//
//  Main list view for assignments grouped by year with filtering
//

import SwiftUI
import SwiftData

/// Main view displaying all assignments with filtering and grouping
struct AssignmentListView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AssignmentViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.assignments.isEmpty {
                    emptyStateView
                } else {
                    assignmentListContent
                }
            }
            .background(TNColors.background)
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
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
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading assignments...")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
                .padding(.top, TNSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: TNSpacing.lg) {
            Spacer()

            Image(systemName: "briefcase")
                .font(.system(size: 64))
                .foregroundStyle(TNColors.textTertiary)

            Text("No Assignments Yet")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            Text("Start tracking your travel nursing assignments to manage your contracts and monitor compliance.")
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.xl)

            Button {
                viewModel.showingAddSheet = true
            } label: {
                Label("Add Your First Assignment", systemImage: "plus")
                    .font(TNTypography.buttonMedium)
            }
            .buttonStyle(.borderedProminent)
            .tint(TNColors.primary)

            Spacer()
        }
    }

    // MARK: - Assignment List Content

    private var assignmentListContent: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar

            // Assignment list grouped by year
            ScrollView {
                LazyVStack(spacing: TNSpacing.md, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.assignmentYears, id: \.self) { year in
                        Section {
                            ForEach(viewModel.assignments(forYear: year)) { assignment in
                                AssignmentRow(assignment: assignment)
                                    .onTapGesture {
                                        viewModel.selectAssignment(assignment)
                                    }
                            }
                        } header: {
                            yearHeader(for: year)
                        }
                    }
                }
                .padding(TNSpacing.md)
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(AssignmentFilterStatus.allCases) { filter in
                    FilterChip(
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
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.sm)
        }
        .background(TNColors.surface)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Year Header

    private func yearHeader(for year: Int) -> some View {
        HStack {
            Text(String(year))
                .font(TNTypography.headlineSmall)
                .foregroundStyle(TNColors.textPrimary)

            Spacer()

            Text("\(viewModel.assignments(forYear: year).count) assignments")
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textSecondary)
        }
        .padding(.vertical, TNSpacing.sm)
        .padding(.horizontal, TNSpacing.xs)
        .background(TNColors.background)
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

// MARK: - Filter Chip Component

struct FilterChip: View {
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
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(TNColors.border, lineWidth: 1)
                }
            }
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
