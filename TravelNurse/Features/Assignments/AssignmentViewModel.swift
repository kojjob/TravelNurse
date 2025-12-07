//
//  AssignmentViewModel.swift
//  TravelNurse
//
//  ViewModel for the Assignments feature with CRUD operations
//

import Foundation
import SwiftUI

/// Filter options for assignment list
enum AssignmentFilterStatus: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case upcoming = "Upcoming"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var id: String { rawValue }

    var assignmentStatus: AssignmentStatus? {
        switch self {
        case .all: return nil
        case .active: return .active
        case .upcoming: return .upcoming
        case .completed: return .completed
        case .cancelled: return .cancelled
        }
    }
}

/// ViewModel for managing assignments
@MainActor
@Observable
final class AssignmentViewModel {

    // MARK: - Published State

    var isLoading = false
    var errorMessage: String?
    var filterStatus: AssignmentFilterStatus = .all
    var selectedAssignment: Assignment?
    var showingAddSheet = false
    var showingEditSheet = false

    // MARK: - Data

    private(set) var assignments: [Assignment] = []

    // MARK: - Dependencies

    private var service: AssignmentServiceProtocol?

    // MARK: - Initialization

    init(service: AssignmentServiceProtocol? = nil) {
        self.service = service
    }

    // MARK: - Computed Properties

    /// Assignments filtered by current filter status
    var filteredAssignments: [Assignment] {
        guard filterStatus != .all else { return assignments }

        guard let status = filterStatus.assignmentStatus else { return assignments }

        return assignments.filter { $0.status == status }
    }

    /// Current active assignment (if any)
    var currentAssignment: Assignment? {
        assignments.first { $0.status == .active }
    }

    /// Unique years from all assignments, sorted descending
    var assignmentYears: [Int] {
        let years = Set(assignments.map { Calendar.current.component(.year, from: $0.startDate) })
        return years.sorted(by: >)
    }

    /// Total number of assignments
    var totalAssignments: Int {
        assignments.count
    }

    /// Count of active assignments
    var activeAssignmentsCount: Int {
        assignments.filter { $0.status == .active }.count
    }

    /// Count of completed assignments
    var completedAssignmentsCount: Int {
        assignments.filter { $0.status == .completed }.count
    }

    /// Count of upcoming assignments
    var upcomingAssignmentsCount: Int {
        assignments.filter { $0.status == .upcoming }.count
    }

    // MARK: - Public Methods

    /// Configure service (for cases where service isn't available at init)
    func configure(with service: AssignmentServiceProtocol) {
        self.service = service
    }

    /// Load all assignments from the service
    func loadAssignments() {
        guard let service = service else {
            configureFromContainer()
            return
        }

        isLoading = true
        errorMessage = nil

        assignments = service.fetchAllOrEmpty()

        isLoading = false
    }

    /// Get assignments for a specific year
    func assignments(forYear year: Int) -> [Assignment] {
        filteredAssignments.filter {
            Calendar.current.component(.year, from: $0.startDate) == year
        }
    }

    /// Add a new assignment
    func addAssignment(_ assignment: Assignment) {
        guard let service = service else { return }
        service.createQuietly(assignment)
        loadAssignments()
    }

    /// Update an existing assignment
    func updateAssignment(_ assignment: Assignment) {
        guard let service = service else { return }
        service.updateQuietly(assignment)
        loadAssignments()
    }

    /// Delete an assignment
    func deleteAssignment(_ assignment: Assignment) {
        guard let service = service else { return }
        service.deleteQuietly(assignment)
        loadAssignments()
    }

    /// Select an assignment for viewing/editing
    func selectAssignment(_ assignment: Assignment) {
        selectedAssignment = assignment
    }

    /// Clear the current selection
    func clearSelection() {
        selectedAssignment = nil
    }

    /// Refresh assignments from the service
    func refresh() {
        loadAssignments()
    }

    // MARK: - Private Methods

    private func configureFromContainer() {
        do {
            service = try ServiceContainer.shared.getAssignmentService()
            loadAssignments()
        } catch {
            errorMessage = "Failed to initialize service: \(error.localizedDescription)"
        }
    }
}

// MARK: - Form State

extension AssignmentViewModel {
    /// Check if we have any assignments at all
    var hasAssignments: Bool {
        !assignments.isEmpty
    }

    /// Check if there's a warning (approaching one-year limit)
    var hasOneYearWarning: Bool {
        assignments.contains { $0.isApproachingOneYearLimit }
    }

    /// Assignments approaching the IRS one-year limit
    var assignmentsApproachingLimit: [Assignment] {
        assignments.filter { $0.isApproachingOneYearLimit }
    }
}
