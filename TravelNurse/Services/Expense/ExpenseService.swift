//
//  ExpenseService.swift
//  TravelNurse
//
//  Service layer for Expense CRUD operations
//

import Foundation
import SwiftData

/// Protocol defining Expense service operations
public protocol ExpenseServiceProtocol {
    func create(_ expense: Expense) -> Result<Void, ServiceError>
    func fetchAll() -> Result<[Expense], ServiceError>
    func fetch(byId id: UUID) -> Result<Expense?, ServiceError>
    func fetch(byCategory category: ExpenseCategory) -> Result<[Expense], ServiceError>
    func fetch(byYear year: Int) -> Result<[Expense], ServiceError>
    func fetch(forAssignment assignment: Assignment) -> Result<[Expense], ServiceError>
    func fetchDeductible() -> Result<[Expense], ServiceError>
    func fetchRecent(limit: Int) -> Result<[Expense], ServiceError>
    func update(_ expense: Expense) -> Result<Void, ServiceError>
    func delete(_ expense: Expense) -> Result<Void, ServiceError>
    func totalExpenses(forYear year: Int) -> Decimal
    func totalDeductible(forYear year: Int) -> Decimal
    func expensesByCategory(forYear year: Int) -> [ExpenseCategory: Decimal]
}

// MARK: - Protocol Extension for Backward Compatibility

extension ExpenseServiceProtocol {
    /// Fetches all expenses, returning empty array on failure
    public func fetchAllOrEmpty() -> [Expense] {
        fetchAll().valueOrDefault([], category: .expense)
    }

    /// Fetches expenses by year, returning empty array on failure
    public func fetchByYearOrEmpty(_ year: Int) -> [Expense] {
        fetch(byYear: year).valueOrDefault([], category: .expense)
    }

    /// Fetches recent expenses, returning empty array on failure
    public func fetchRecentOrEmpty(limit: Int = 10) -> [Expense] {
        fetchRecent(limit: limit).valueOrDefault([], category: .expense)
    }

    /// Creates an expense without Result handling
    public func createQuietly(_ expense: Expense) {
        _ = create(expense)
    }

    /// Updates an expense without Result handling
    public func updateQuietly(_ expense: Expense) {
        _ = update(expense)
    }

    /// Deletes an expense without Result handling
    public func deleteQuietly(_ expense: Expense) {
        _ = delete(expense)
    }
}

/// Service for managing Expense data operations
@MainActor
public final class ExpenseService: ExpenseServiceProtocol {

    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Creates a new expense in the data store
    public func create(_ expense: Expense) -> Result<Void, ServiceError> {
        expense.updatedAt = Date()
        modelContext.insert(expense)
        return save(operation: "create expense")
    }

    /// Fetches all expenses sorted by date (newest first)
    public func fetchAll() -> Result<[Expense], ServiceError> {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let expenses = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(expenses.count) expenses", category: .expense)
            return .success(expenses)
        } catch {
            ServiceLogger.logFetchError("all expenses", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "expenses", underlying: error.localizedDescription))
        }
    }

    /// Fetches a single expense by its unique ID
    public func fetch(byId id: UUID) -> Result<Expense?, ServiceError> {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            let expense = try modelContext.fetch(descriptor).first
            if expense != nil {
                ServiceLogger.logSuccess("Fetched expense by ID", category: .expense)
            }
            return .success(expense)
        } catch {
            ServiceLogger.logFetchError("expense by ID: \(id)", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "expense by ID", underlying: error.localizedDescription))
        }
    }

    /// Fetches expenses filtered by category
    public func fetch(byCategory category: ExpenseCategory) -> Result<[Expense], ServiceError> {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.categoryRaw == categoryRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let expenses = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(expenses.count) expenses for category: \(category)", category: .expense)
            return .success(expenses)
        } catch {
            ServiceLogger.logFetchError("expenses by category: \(category)", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "expenses by category", underlying: error.localizedDescription))
        }
    }

    /// Fetches expenses for a specific tax year
    public func fetch(byYear year: Int) -> Result<[Expense], ServiceError> {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.taxYear == year },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let expenses = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(expenses.count) expenses for year: \(year)", category: .expense)
            return .success(expenses)
        } catch {
            ServiceLogger.logFetchError("expenses by year: \(year)", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "expenses by year", underlying: error.localizedDescription))
        }
    }

    /// Fetches expenses associated with a specific assignment
    public func fetch(forAssignment assignment: Assignment) -> Result<[Expense], ServiceError> {
        let assignmentId = assignment.id
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.assignment?.id == assignmentId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let expenses = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(expenses.count) expenses for assignment", category: .expense)
            return .success(expenses)
        } catch {
            ServiceLogger.logFetchError("expenses for assignment", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "expenses for assignment", underlying: error.localizedDescription))
        }
    }

    /// Fetches all deductible expenses
    public func fetchDeductible() -> Result<[Expense], ServiceError> {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isDeductible == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let expenses = try modelContext.fetch(descriptor)
            ServiceLogger.logSuccess("Fetched \(expenses.count) deductible expenses", category: .expense)
            return .success(expenses)
        } catch {
            ServiceLogger.logFetchError("deductible expenses", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "deductible expenses", underlying: error.localizedDescription))
        }
    }

    /// Updates an existing expense
    public func update(_ expense: Expense) -> Result<Void, ServiceError> {
        expense.updatedAt = Date()
        return save(operation: "update expense")
    }

    /// Deletes an expense from the data store
    public func delete(_ expense: Expense) -> Result<Void, ServiceError> {
        modelContext.delete(expense)
        return save(operation: "delete expense")
    }

    // MARK: - Statistics

    /// Calculates total expenses for a given year
    public func totalExpenses(forYear year: Int) -> Decimal {
        let expenses = fetch(byYear: year).valueOrDefault([], category: .expense)
        return expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Calculates total deductible expenses for a given year
    public func totalDeductible(forYear year: Int) -> Decimal {
        let expenses = fetch(byYear: year).valueOrDefault([], category: .expense).filter { $0.isDeductible }
        return expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Groups expenses by category with totals for a given year
    public func expensesByCategory(forYear year: Int) -> [ExpenseCategory: Decimal] {
        let expenses = fetch(byYear: year).valueOrDefault([], category: .expense)
        var result: [ExpenseCategory: Decimal] = [:]

        for expense in expenses {
            let current = result[expense.category] ?? Decimal.zero
            result[expense.category] = current + expense.amount
        }

        return result
    }

    /// Returns count of expenses for a category in a year
    public func expenseCount(byCategory category: ExpenseCategory, year: Int) -> Int {
        fetch(byYear: year).valueOrDefault([], category: .expense).filter { $0.category == category }.count
    }

    /// Returns recent expenses (last 30 days)
    public func fetchRecent(limit: Int = 10) -> Result<[Expense], ServiceError> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= thirtyDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            var result = try modelContext.fetch(descriptor)
            if result.count > limit {
                result = Array(result.prefix(limit))
            }
            ServiceLogger.logSuccess("Fetched \(result.count) recent expenses", category: .expense)
            return .success(result)
        } catch {
            ServiceLogger.logFetchError("recent expenses", error: error, category: .expense)
            return .failure(.fetchFailed(operation: "recent expenses", underlying: error.localizedDescription))
        }
    }

    // MARK: - Private Helpers

    private func save(operation: String) -> Result<Void, ServiceError> {
        do {
            try modelContext.save()
            ServiceLogger.logSuccess("Saved: \(operation)", category: .expense)
            return .success(())
        } catch {
            ServiceLogger.logSaveError(operation, error: error, category: .expense)
            return .failure(.saveFailed(operation: operation, underlying: error.localizedDescription))
        }
    }
}

// MARK: - Convenience Extensions for Backward Compatibility

extension ExpenseService {
    /// Fetches all expenses, returning empty array on failure (backward compatible)
    public func fetchAllOrEmpty() -> [Expense] {
        fetchAll().valueOrDefault([], category: .expense)
    }

    /// Creates an expense without Result handling (backward compatible)
    public func createQuietly(_ expense: Expense) {
        _ = create(expense)
    }

    /// Updates an expense without Result handling (backward compatible)
    public func updateQuietly(_ expense: Expense) {
        _ = update(expense)
    }

    /// Deletes an expense without Result handling (backward compatible)
    public func deleteQuietly(_ expense: Expense) {
        _ = delete(expense)
    }

    /// Fetches recent expenses, returning empty array on failure (backward compatible)
    public func fetchRecentOrEmpty(limit: Int = 10) -> [Expense] {
        fetchRecent(limit: limit).valueOrDefault([], category: .expense)
    }
}
