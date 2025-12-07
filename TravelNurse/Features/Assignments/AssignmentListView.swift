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
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = AssignmentViewModel()
    
    // Animation state for the mesh gradient
    @State private var animateGradient = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Mesh Gradient Background
                meshGradientBackground
                
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.assignments.isEmpty {
                        emptyStateView
                    } else {
                        assignmentListContent
                    }
                }
            }
            .navigationTitle("Assignments")
            .navigationBarHidden(true) // Using custom header
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.loadAssignments()
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddAssignmentView { newAssignment in
                    HapticManager.success()
                    viewModel.addAssignment(newAssignment)
                    viewModel.refresh()
                }
            }
            .sheet(item: $viewModel.selectedAssignment) { assignment in
                AssignmentDetailView(
                    assignment: assignment,
                    onUpdate: { updatedAssignment in
                        HapticManager.success()
                        viewModel.updateAssignment(updatedAssignment)
                        viewModel.refresh()
                    },
                    onDelete: {
                        HapticManager.error()
                        viewModel.deleteAssignment(assignment)
                        viewModel.refresh()
                    }
                )
            }
        }
    }

    // MARK: - Mesh Gradient Background

    private var meshGradientBackground: some View {
        ZStack {
            // Base Color
            (colorScheme == .dark ? Color(hex: "0F172A") : Color.white)
                .ignoresSafeArea()
            
            // Animated Blobs
            GeometryReader { geo in
                ZStack {
                    // Top Left
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "818CF8").opacity(0.4) : Color(hex: "A78BFA").opacity(0.3))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: animateGradient ? -100 : -50, y: animateGradient ? -100 : -150)
                    
                    // Top Right
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "38BDF8").opacity(0.3) : Color(hex: "60A5FA").opacity(0.2))
                        .frame(width: 350, height: 350)
                        .blur(radius: 80)
                        .offset(x: animateGradient ? 150 : 200, y: animateGradient ? -50 : -100)
                    
                    // Center/Bottom
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "FB923C").opacity(0.2) : Color(hex: "F472B6").opacity(0.2))
                        .frame(width: 300, height: 300)
                        .blur(radius: 90)
                        .offset(x: animateGradient ? 50 : -50, y: animateGradient ? 200 : 250)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(TNColors.primary)
            Text("Loading assignments...")
                .font(.subheadline)
                .foregroundStyle(TNColors.textSecondary)
                .padding(.top, TNSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: TNSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(TNColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "briefcase.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(TNColors.primary)
            }
            .padding(.bottom, TNSpacing.md)

            Text("No Assignments Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)

            Text("Start tracking your travel nursing assignments to manage your contracts and monitor compliance.")
                .font(.body)
                .foregroundStyle(TNColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TNSpacing.xl)

            Button {
                viewModel.showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Your First Assignment")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, TNSpacing.xl)
                .padding(.vertical, TNSpacing.md)
                .background(TNColors.primary)
                .clipShape(Capsule())
                .shadow(color: TNColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, TNSpacing.md)

            Spacer()
        }
    }

    // MARK: - Assignment List Content

    private var assignmentListContent: some View {
        VStack(spacing: 0) {
            // Custom Header
            headerView
            
            // Filter bar
            filterBar
                .padding(.bottom, TNSpacing.sm)

            // Assignment list grouped by year
            ScrollView {
                LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.assignmentYears, id: \.self) { year in
                        Section {
                            ForEach(viewModel.assignments(forYear: year)) { assignment in
                                AssignmentRow(assignment: assignment)
                                    .onTapGesture {
                                        viewModel.selectAssignment(assignment)
                                    }
                            }
                            .onDelete { indexSet in
                                HapticManager.error()
                                let yearAssignments = viewModel.assignments(forYear: year)
                                for index in indexSet {
                                    if index < yearAssignments.count {
                                        let assignmentToDelete = yearAssignments[index]
                                        viewModel.deleteAssignment(assignmentToDelete)
                                    }
                                }
                                viewModel.refresh()
                            }
                        } header: {
                            yearHeader(for: year)
                        }
                    }
                }
                .padding(TNSpacing.md)
                .padding(.bottom, 80) // Space for FAB if needed or bottom safe area
            }
        }
    }
    
    // MARK: - Custom Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), format: .dateTime.weekday(.wide).month().day())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(TNColors.textSecondary)
                    .textCase(.uppercase)
                
                Text("Assignments")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(TNColors.textPrimary)
            }
            
            Spacer()
            
            Button {
                viewModel.showingAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(TNColors.primary)
                    .clipShape(Circle())
                    .shadow(color: TNColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, TNSpacing.md)
        .padding(.top, TNSpacing.md)
        .padding(.bottom, TNSpacing.sm)
        .background(.ultraThinMaterial) // Glass effect
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AssignmentFilterStatus.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.filterStatus == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.filterStatus = filter
                        }
                    }
                }
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Year Header

    private func yearHeader(for year: Int) -> some View {
        HStack {
            Text(String(year))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)

            Spacer()

            Text("\(viewModel.assignments(forYear: year).count) assignments")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(TNColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, TNSpacing.xs)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.8),
                        .init(color: .clear, location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                )
        )
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
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)

                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white.opacity(0.25) : TNColors.textSecondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isSelected ? .white : TNColors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            colors: [Color(hex: "818CF8"), Color(hex: "38BDF8")], // Vibrant Purple/Blue
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
            )
            .clipShape(Capsule())
            .shadow(
                color: isSelected ? Color(hex: "818CF8").opacity(0.3) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.05), lineWidth: 1)
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
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
