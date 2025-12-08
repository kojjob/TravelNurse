//
//  RecurringExpenseService.swift
//  TravelNurse
//
//  Service for managing recurring expenses and generating expense entries
//

import Foundation
import SwiftData

// MARK: - Recurring Expense Summary

/// Summary of recurring expenses for budgeting
public struct RecurringExpenseSummary {
    public let monthlyTotal: Decimal
    public let annualTotal: Decimal
    public let activeCount: Int
    public let byCategory: [ExpenseCategory: Decimal]

    public var formattedMonthlyTotal: String {
        formatCurrency(monthlyTotal)
    }

    public var formattedAnnualTotal: String {
        formatCurrency(annualTotal)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Recurring Expense Service

/// Service for managing recurring expenses
@MainActor
public final class RecurringExpenseService {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Create a new recurring expense
    @discardableResult
    public func create(
        name: String,
        category: ExpenseCategory,
        amount: Decimal,
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date? = nil,
        merchantName: String? = nil,
        notes: String? = nil,
        isDeductible: Bool = true
    ) -> RecurringExpense {
        let recurring = RecurringExpense(
            name: name,
            category: category,
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            merchantName: merchantName,
            notes: notes,
            isDeductible: isDeductible
        )
        recurring.endDate = endDate

        modelContext.insert(recurring)
        saveContext()

        return recurring
    }

    // MARK: - Fetch

    /// Fetch all recurring expenses
    public func fetchAll() -> [RecurringExpense] {
        let descriptor = FetchDescriptor<RecurringExpense>(
            sortBy: [SortDescriptor(\.name)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching recurring expenses: \(error)")
            return []
        }
    }

    /// Fetch only active recurring expenses
    public func fetchActive() -> [RecurringExpense] {
        let descriptor = FetchDescriptor<RecurringExpense>(
            predicate: RecurringExpense.activePredicate,
            sortBy: [SortDescriptor(\.name)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching active recurring expenses: \(error)")
            return []
        }
    }

    /// Fetch recurring expenses that are due
    public func fetchDue() -> [RecurringExpense] {
        let active = fetchActive()
        return active.filter { $0.isDue }
    }

    /// Fetch recurring expenses by category
    public func fetchByCategory(_ category: ExpenseCategory) -> [RecurringExpense] {
        let descriptor = FetchDescriptor<RecurringExpense>(
            predicate: RecurringExpense.categoryPredicate(category),
            sortBy: [SortDescriptor(\.name)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching recurring expenses by category: \(error)")
            return []
        }
    }

    // MARK: - Generate Expenses

    /// Generate an expense from a recurring expense if due
    @discardableResult
    public func generateExpense(from recurring: RecurringExpense) -> Expense? {
        guard recurring.isDue else { return nil }

        let expense = Expense(
            category: recurring.category,
            amount: recurring.amount,
            date: recurring.nextOccurrence ?? Date(),
            merchantName: recurring.merchantName,
            notes: "Auto-generated from: \(recurring.name)",
            isDeductible: recurring.isDeductible
        )

        modelContext.insert(expense)
        recurring.recordGeneration(date: expense.date)
        saveContext()

        return expense
    }

    /// Process all due recurring expenses and generate entries
    public func processAllDue() -> [Expense] {
        let dueExpenses = fetchDue()
        var generated: [Expense] = []

        for recurring in dueExpenses {
            if let expense = generateExpense(from: recurring) {
                generated.append(expense)
            }
        }

        return generated
    }

    // MARK: - Update

    /// Update a recurring expense's amount
    public func update(_ recurring: RecurringExpense, amount: Decimal) {
        recurring.amount = amount
        recurring.updatedAt = Date()
        saveContext()
    }

    /// Update a recurring expense's frequency
    public func update(_ recurring: RecurringExpense, frequency: RecurrenceFrequency) {
        recurring.frequency = frequency
        recurring.updatedAt = Date()
        saveContext()
    }

    /// Update multiple properties at once
    public func update(
        _ recurring: RecurringExpense,
        name: String? = nil,
        category: ExpenseCategory? = nil,
        amount: Decimal? = nil,
        frequency: RecurrenceFrequency? = nil,
        merchantName: String? = nil,
        notes: String? = nil,
        isDeductible: Bool? = nil
    ) {
        if let name = name { recurring.name = name }
        if let category = category { recurring.category = category }
        if let amount = amount { recurring.amount = amount }
        if let frequency = frequency { recurring.frequency = frequency }
        if let merchantName = merchantName { recurring.merchantName = merchantName }
        if let notes = notes { recurring.notes = notes }
        if let isDeductible = isDeductible { recurring.isDeductible = isDeductible }

        recurring.updatedAt = Date()
        saveContext()
    }

    // MARK: - Delete

    /// Delete a recurring expense
    public func delete(_ recurring: RecurringExpense) {
        modelContext.delete(recurring)
        saveContext()
    }

    // MARK: - Pause/Resume

    /// Pause a recurring expense (stop generating)
    public func pause(_ recurring: RecurringExpense) {
        recurring.pause()
        saveContext()
    }

    /// Resume a paused recurring expense
    public func resume(_ recurring: RecurringExpense) {
        recurring.resume()
        saveContext()
    }

    // MARK: - Summary

    /// Get monthly summary of recurring expenses
    public func monthlySummary() -> RecurringExpenseSummary {
        let active = fetchActive()

        var monthlyTotal: Decimal = 0
        var byCategory: [ExpenseCategory: Decimal] = [:]

        for recurring in active {
            let monthly = recurring.monthlyEstimate
            monthlyTotal += monthly

            let category = recurring.category
            byCategory[category, default: 0] += monthly
        }

        return RecurringExpenseSummary(
            monthlyTotal: monthlyTotal,
            annualTotal: monthlyTotal * 12,
            activeCount: active.count,
            byCategory: byCategory
        )
    }

    // MARK: - Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
