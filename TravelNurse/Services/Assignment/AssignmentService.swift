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
    func create(_ assignment: Assignment) -> Result<Void, ServiceError>
    func fetchAll() -> Result<[Assignment], ServiceError>
    func fetch(byId id: UUID) -> Result<Assignment?, ServiceError>
    func fetch(byStatus status: AssignmentStatus) -> Result<[Assignment], ServiceError>
    func fetch(byYear year: Int) -> Result<[Assignment], ServiceError>
    func fetchCurrentAssignment() -> Result<Assignment?, ServiceError>
    func update(_ assignment: Assignment) -> Result<Void, ServiceError>
    func delete(_ assignment: Assignment) -> Result<Void, ServiceError>
    func totalEarnings(forYear year: Int) -> Decimal
    func assignmentCount(withStatus status: AssignmentStatus) -> Int
}

// MARK: - Protocol Extension for Backward Compatibility

extension AssignmentServiceProtocol {
    /// Fetches all assignments, returning empty array on failure
    public func fetchAllOrEmpty() -> [Assignment] {
        fetchAll().valueOrDefault([], category: .assignment)
    }

    /// Fetches current assignment, returning nil on failure
    public func fetchCurrentAssignmentOrNil() -> Assignment? {
        fetchCurrentAssignment().valueOrLog(category: .assignment) ?? nil
    }

    /// Fetches assignments by year, returning empty array on failure
    public func fetchByYearOrEmpty(_ year: Int) -> [Assignment] {
        fetch(byYear: year).valueOrDefault([], category: .assignment)
    }

    /// Creates an assignment without Result handling
    public func createQuietly(_ assignment: Assignment) {
        _ = create(assignment)
    }

    /// Updates an assignment without Result handling
    public func updateQuietly(_ assignment: Assignment) {
        _ = update(assignment)
    }

    /// Deletes an assignment without Result handling
    public func deleteQuietly(_ assignment: Assignment) {
        _ = delete(assignment)
    }
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
    public func create(_ assignment: Assignment) -> Result<Void, ServiceError> {
        assignment.updatedAt = Date()
        modelContext.insert(assignment)
        return save(operation: "create assignment")
    }

    /// Fetches all assignments sorted by start date (newest first)
    public func fetchAll() -> Result<[Assignment], ServiceError> {
        let descriptor = FetchDescriptor<Assignment>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let assignments = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(assignments.count) assignments", category: .assignment)
            return .success(assignments)
        } catch {
            ServiceLogger.logFetchError("all assignments", error: error, category: .assignment)
            return .failure(.fetchFailed(operation: "assignments", underlying: error.localizedDescription))
        }
    }

    /// Fetches a single assignment by its unique ID
    public func fetch(byId id: UUID) -> Result<Assignment?, ServiceError> {
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let assignment = try modelContext.fetch(descriptor).first
            if assignment != nil {
                ServiceLogger.logSuccess("Fetched assignment by ID", category: .assignment)
            }
            return .success(assignment)
        } catch {
            ServiceLogger.logFetchError("assignment by ID: \(id)", error: error, category: .assignment)
            return .failure(.fetchFailed(operation: "assignment by ID", underlying: error.localizedDescription))
        }
    }

    /// Fetches assignments filtered by status
    public func fetch(byStatus status: AssignmentStatus) -> Result<[Assignment], ServiceError> {
        let statusRaw = status.rawValue
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.statusRaw == statusRaw },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let assignments = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(assignments.count) assignments with status: \(status)", category: .assignment)
            return .success(assignments)
        } catch {
            ServiceLogger.logFetchError("assignments by status: \(status)", error: error, category: .assignment)
            return .failure(.fetchFailed(operation: "assignments by status", underlying: error.localizedDescription))
        }
    }

    /// Fetches assignments that started in a specific year
    public func fetch(byYear year: Int) -> Result<[Assignment], ServiceError> {
        let calendar = Calendar.current
        guard let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            return .failure(.invalidInput(field: "year", reason: "Could not create date range for year \(year)"))
        }

        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.startDate >= startOfYear && $0.startDate < endOfYear },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let assignments = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(assignments.count) assignments for year: \(year)", category: .assignment)
            return .success(assignments)
        } catch {
            ServiceLogger.logFetchError("assignments by year: \(year)", error: error, category: .assignment)
            return .failure(.fetchFailed(operation: "assignments by year", underlying: error.localizedDescription))
        }
    }

    /// Fetches the current active assignment (if any)
    public func fetchCurrentAssignment() -> Result<Assignment?, ServiceError> {
        switch fetch(byStatus: .active) {
        case .success(let assignments):
            return .success(assignments.first)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Updates an existing assignment
    public func update(_ assignment: Assignment) -> Result<Void, ServiceError> {
        assignment.updatedAt = Date()
        return save(operation: "update assignment")
    }

    /// Deletes an assignment from the data store
    public func delete(_ assignment: Assignment) -> Result<Void, ServiceError> {
        modelContext.delete(assignment)
        return save(operation: "delete assignment")
    }

    // MARK: - Statistics

    /// Calculates total expected earnings for assignments in a given year
    public func totalEarnings(forYear year: Int) -> Decimal {
        let assignments = fetch(byYear: year).valueOrDefault([], category: .assignment)
        return assignments.reduce(Decimal.zero) { total, assignment in
            total + assignment.totalExpectedPay
        }
    }

    /// Returns count of assignments with a specific status
    public func assignmentCount(withStatus status: AssignmentStatus) -> Int {
        fetch(byStatus: status).valueOrDefault([], category: .assignment).count
    }

    // MARK: - Additional Queries

    /// Fetches assignments for a specific user
    public func fetch(forUser user: UserProfile) -> Result<[Assignment], ServiceError> {
        let userId = user.id
        let descriptor = FetchDescriptor<Assignment>(
            predicate: #Predicate { $0.user?.id == userId },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            let assignments = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(assignments.count) assignments for user", category: .assignment)
            return .success(assignments)
        } catch {
            ServiceLogger.logFetchError("assignments for user", error: error, category: .assignment)
            return .failure(.fetchFailed(operation: "assignments for user", underlying: error.localizedDescription))
        }
    }

    /// Fetches upcoming assignments (status = upcoming)
    public func fetchUpcoming() -> Result<[Assignment], ServiceError> {
        fetch(byStatus: .upcoming)
    }

    /// Fetches completed assignments
    public func fetchCompleted() -> Result<[Assignment], ServiceError> {
        fetch(byStatus: .completed)
    }

    /// Checks if user has any assignment approaching one-year limit
    public func hasAssignmentsApproachingLimit() -> Bool {
        fetchAll().valueOrDefault([], category: .assignment).contains { $0.isApproachingOneYearLimit }
    }

    /// Gets assignments grouped by year
    public func assignmentsGroupedByYear() -> [Int: [Assignment]] {
        let allAssignments = fetchAll().valueOrDefault([], category: .assignment)
        let calendar = Calendar.current

        return Dictionary(grouping: allAssignments) { assignment in
            calendar.component(.year, from: assignment.startDate)
        }
    }

    // MARK: - Private Helpers

    private func save(operation: String) -> Result<Void, ServiceError> {
        do {
            try modelContext.save()
            ServiceLogger.logSuccess("Saved: \(operation)", category: .assignment)
            return .success(())
        } catch {
            ServiceLogger.logSaveError(operation, error: error, category: .assignment)
            return .failure(.saveFailed(operation: operation, underlying: error.localizedDescription))
        }
    }
}

// MARK: - Convenience Extensions for Backward Compatibility

extension AssignmentService {
    /// Fetches all assignments, returning empty array on failure (backward compatible)
    public func fetchAllOrEmpty() -> [Assignment] {
        fetchAll().valueOrDefault([], category: .assignment)
    }

    /// Fetches current assignment, returning nil on failure (backward compatible)
    public func fetchCurrentAssignmentOrNil() -> Assignment? {
        fetchCurrentAssignment().valueOrLog(category: .assignment) ?? nil
    }

    /// Creates an assignment without Result handling (backward compatible)
    public func createQuietly(_ assignment: Assignment) {
        _ = create(assignment)
    }

    /// Updates an assignment without Result handling (backward compatible)
    public func updateQuietly(_ assignment: Assignment) {
        _ = update(assignment)
    }

    /// Deletes an assignment without Result handling (backward compatible)
    public func deleteQuietly(_ assignment: Assignment) {
        _ = delete(assignment)
    }
}
