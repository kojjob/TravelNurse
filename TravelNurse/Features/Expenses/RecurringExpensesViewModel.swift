//
//  RecurringExpensesViewModel.swift
//  TravelNurse
//
//  ViewModel for managing recurring expenses
//

import Foundation
import SwiftUI
import SwiftData

/// Quick add templates for common recurring expenses
enum RecurringExpenseTemplate {
    case housing
    case cellPhone
    case internet
    case insurance

    var name: String {
        switch self {
        case .housing: return "Assignment Housing"
        case .cellPhone: return "Cell Phone"
        case .internet: return "Internet"
        case .insurance: return "Liability Insurance"
        }
    }

    var category: ExpenseCategory {
        switch self {
        case .housing: return .rent
        case .cellPhone: return .cellPhone
        case .internet: return .internet
        case .insurance: return .liability
        }
    }

    var suggestedFrequency: RecurrenceFrequency {
        switch self {
        case .housing, .cellPhone, .internet: return .monthly
        case .insurance: return .annually
        }
    }
}

/// ViewModel for RecurringExpensesView
@MainActor
@Observable
final class RecurringExpensesViewModel {

    // MARK: - State

    private(set) var recurringExpenses: [RecurringExpense] = []
    private(set) var summary: RecurringExpenseSummary = RecurringExpenseSummary(
        monthlyTotal: 0,
        annualTotal: 0,
        activeCount: 0,
        byCategory: [:]
    )
    private(set) var isLoading = false

    /// Currently selected template for quick add
    var selectedTemplate: RecurringExpenseTemplate?

    // MARK: - Computed Properties

    var activeExpenses: [RecurringExpense] {
        recurringExpenses.filter { $0.isActive }
    }

    var pausedExpenses: [RecurringExpense] {
        recurringExpenses.filter { !$0.isActive }
    }

    var dueCount: Int {
        recurringExpenses.filter { $0.isDue }.count
    }

    // MARK: - Dependencies

    private var service: RecurringExpenseService?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    nonisolated init() {}

    // MARK: - Actions

    /// Load recurring expenses data
    func loadData(modelContext: ModelContext) async {
        self.modelContext = modelContext
        self.service = RecurringExpenseService(modelContext: modelContext)

        isLoading = true
        await refresh()
        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        guard let service = service else { return }

        recurringExpenses = service.fetchAll()
        summary = service.monthlySummary()
    }

    /// Create a new recurring expense
    func create(
        name: String,
        category: ExpenseCategory,
        amount: Decimal,
        frequency: RecurrenceFrequency,
        merchantName: String?
    ) {
        guard let service = service else { return }

        service.create(
            name: name,
            category: category,
            amount: amount,
            frequency: frequency,
            startDate: Date(),
            merchantName: merchantName
        )

        Task {
            await refresh()
        }
    }

    /// Update an existing recurring expense
    func update(_ expense: RecurringExpense) {
        guard let service = service else { return }

        service.update(
            expense,
            name: expense.name,
            category: expense.category,
            amount: expense.amount,
            frequency: expense.frequency,
            merchantName: expense.merchantName
        )

        Task {
            await refresh()
        }
    }

    /// Delete a recurring expense
    func delete(_ expense: RecurringExpense) {
        guard let service = service else { return }

        service.delete(expense)

        Task {
            await refresh()
        }
    }

    /// Pause a recurring expense
    func pause(_ expense: RecurringExpense) {
        guard let service = service else { return }

        service.pause(expense)

        Task {
            await refresh()
        }
    }

    /// Resume a paused recurring expense
    func resume(_ expense: RecurringExpense) {
        guard let service = service else { return }

        service.resume(expense)

        Task {
            await refresh()
        }
    }

    /// Process all due expenses (generate expense records)
    func processAllDue() -> [Expense] {
        guard let service = service else { return [] }

        let generated = service.processAllDue()

        Task {
            await refresh()
        }

        return generated
    }

    /// Set up for quick add with a template
    func quickAdd(template: RecurringExpenseTemplate) {
        selectedTemplate = template
    }
}
