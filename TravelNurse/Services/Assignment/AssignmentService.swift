//
//  AssignmentService.swift
//  TravelNurse
//
//  Service layer for Assignment CRUD operations
//

import Foundation
import SwiftData

/// Protocol defining Assignment service operations
public protocol AssignmentServiceProtocol {
    func create(_ assignment: Assignment)
    func fetchAll() -> [Assignment]
    func fetch(byId id: UUID) -> Assignment?
    func fetch(byStatus status: AssignmentStatus) -> [Assignment]
    func fetch(byYear year: Int) -> [Assignment]
    func fetchCurrentAssignment() -> Assignment?
    func update(_ assignment: Assignment)
    func delete(_ assignment: Assignment)
    func totalEarnings(forYear year: Int) -> Decimal
    func assignmentCount(withStatus status: AssignmentStatus) -> Int
}

/// Service for managing Assignment data operations
@MainActor
public final class AssignmentService: AssignmentServiceProtocol {

    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Creates a new assignment in the data store
    public func create(_ assignment: Assignment) {
        assignment.updatedAt = Date()
        modelContext.insert(assignment)
        save()
    }

    /// Fetches all assignments sorted by start date (newest first)
    public func fetchAll() -> [Assignment] {
        let descriptor = FetchDescriptor<Assignment>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching assignments: \(error)")
            return []
        }
    }

    /// Fetches a single assignment by its unique ID
    public func fetch(byId id: UUID) -> Assignment? {
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching assignment by ID: \(error)")
            return nil
        }
    }

    /// Fetches assignments filtered by status
    public func fetch(byStatus status: AssignmentStatus) -> [Assignment] {
        let statusRaw = status.rawValue
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.statusRaw == statusRaw },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching assignments by status: \(error)")
            return []
        }
    }

    /// Fetches assignments that started in a specific year
    public func fetch(byYear year: Int) -> [Assignment] {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return []
        }

        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.startDate >= startOfYear && $0.startDate < endOfYear },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching assignments by year: \(error)")
            return []
        }
    }

    /// Fetches the current active assignment (if any)
    public func fetchCurrentAssignment() -> Assignment? {
        fetch(byStatus: .active).first
    }

    /// Updates an existing assignment
    public func update(_ assignment: Assignment) {
        assignment.updatedAt = Date()
        save()
    }

    /// Deletes an assignment from the data store
    public func delete(_ assignment: Assignment) {
        modelContext.delete(assignment)
        save()
    }

    // MARK: - Statistics

    /// Calculates total expected earnings for assignments in a given year
    public func totalEarnings(forYear year: Int) -> Decimal {
        let assignments = fetch(byYear: year)
        return assignments.reduce(Decimal.zero) { total, assignment in
            total + assignment.totalExpectedPay
        }
    }

    /// Returns count of assignments with a specific status
    public func assignmentCount(withStatus status: AssignmentStatus) -> Int {
        fetch(byStatus: status).count
    }

    // MARK: - Additional Queries

    /// Fetches assignments for a specific user
    public func fetch(forUser user: UserProfile) -> [Assignment] {
        let userId = user.id
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.user?.id == userId },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching assignments for user: \(error)")
            return []
        }
    }

    /// Fetches upcoming assignments (status = upcoming)
    public func fetchUpcoming() -> [Assignment] {
        fetch(byStatus: .upcoming)
    }

    /// Fetches completed assignments
    public func fetchCompleted() -> [Assignment] {
        fetch(byStatus: .completed)
    }

    /// Checks if user has any assignment approaching one-year limit
    public func hasAssignmentsApproachingLimit() -> Bool {
        fetchAll().contains { $0.isApproachingOneYearLimit }
    }

    /// Gets assignments grouped by year
    public func assignmentsGroupedByYear() -> [Int: [Assignment]] {
        let allAssignments = fetchAll()
        let calendar = Calendar.current

        return Dictionary(grouping: allAssignments) { assignment in
            calendar.component(.year, from: assignment.startDate)
        }
    }

    // MARK: - Private Helpers

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
