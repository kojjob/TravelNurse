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
    func create(_ expense: Expense)
    func fetchAll() -> [Expense]
    func fetch(byId id: UUID) -> Expense?
    func fetch(byCategory category: ExpenseCategory) -> [Expense]
    func fetch(byYear year: Int) -> [Expense]
    func fetch(forAssignment assignment: Assignment) -> [Expense]
    func fetchDeductible() -> [Expense]
    func update(_ expense: Expense)
    func delete(_ expense: Expense)
    func totalExpenses(forYear year: Int) -> Decimal
    func totalDeductible(forYear year: Int) -> Decimal
    func expensesByCategory(forYear year: Int) -> [ExpenseCategory: Decimal]
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
    public func create(_ expense: Expense) {
        expense.updatedAt = Date()
        modelContext.insert(expense)
        save()
    }

    /// Fetches all expenses sorted by date (newest first)
    public func fetchAll() -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }

    /// Fetches a single expense by its unique ID
    public func fetch(byId id: UUID) -> Expense? {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching expense by ID: \(error)")
            return nil
        }
    }

    /// Fetches expenses filtered by category
    public func fetch(byCategory category: ExpenseCategory) -> [Expense] {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.categoryRaw == categoryRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching expenses by category: \(error)")
            return []
        }
    }

    /// Fetches expenses for a specific tax year
    public func fetch(byYear year: Int) -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.taxYear == year },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching expenses by year: \(error)")
            return []
        }
    }

    /// Fetches expenses associated with a specific assignment
    public func fetch(forAssignment assignment: Assignment) -> [Expense] {
        let assignmentId = assignment.id
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.assignment?.id == assignmentId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching expenses for assignment: \(error)")
            return []
        }
    }

    /// Fetches all deductible expenses
    public func fetchDeductible() -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isDeductible == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching deductible expenses: \(error)")
            return []
        }
    }

    /// Updates an existing expense
    public func update(_ expense: Expense) {
        expense.updatedAt = Date()
        save()
    }

    /// Deletes an expense from the data store
    public func delete(_ expense: Expense) {
        modelContext.delete(expense)
        save()
    }

    // MARK: - Statistics

    /// Calculates total expenses for a given year
    public func totalExpenses(forYear year: Int) -> Decimal {
        let expenses = fetch(byYear: year)
        return expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Calculates total deductible expenses for a given year
    public func totalDeductible(forYear year: Int) -> Decimal {
        let expenses = fetch(byYear: year).filter { $0.isDeductible }
        return expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Groups expenses by category with totals for a given year
    public func expensesByCategory(forYear year: Int) -> [ExpenseCategory: Decimal] {
        let expenses = fetch(byYear: year)
        var result: [ExpenseCategory: Decimal] = [:]

        for expense in expenses {
            let current = result[expense.category] ?? Decimal.zero
            result[expense.category] = current + expense.amount
        }

        return result
    }

    /// Returns count of expenses for a category in a year
    public func expenseCount(byCategory category: ExpenseCategory, year: Int) -> Int {
        fetch(byYear: year).filter { $0.category == category }.count
    }

    /// Returns recent expenses (last 30 days)
    public func fetchRecent(limit: Int = 10) -> [Expense] {
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
            return result
        } catch {
            print("Error fetching recent expenses: \(error)")
            return []
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
