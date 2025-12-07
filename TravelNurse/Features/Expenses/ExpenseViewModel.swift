//
//  ExpenseViewModel.swift
//  TravelNurse
//
//  ViewModel for the Expenses feature with CRUD operations and statistics
//

import Foundation
import SwiftUI

/// Filter options for expense list
enum ExpenseFilterCategory: Equatable {
    case all
    case category(ExpenseCategory)
    case group(ExpenseGroup)

    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .category(let category):
            return category.displayName
        case .group(let group):
            return group.rawValue
        }
    }

    static func == (lhs: ExpenseFilterCategory, rhs: ExpenseFilterCategory) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all):
            return true
        case (.category(let lhsCat), .category(let rhsCat)):
            return lhsCat == rhsCat
        case (.group(let lhsGroup), .group(let rhsGroup)):
            return lhsGroup == rhsGroup
        default:
            return false
        }
    }
}

/// ViewModel for managing expenses
@MainActor
@Observable
final class ExpenseViewModel {

    // MARK: - Published State

    var isLoading = false
    var errorMessage: String?
    var filterCategory: ExpenseFilterCategory = .all
    var selectedExpense: Expense?
    var showingAddSheet = false
    var showingEditSheet = false

    // MARK: - Data

    private(set) var expenses: [Expense] = []

    // MARK: - Dependencies

    private var service: ExpenseServiceProtocol?

    // MARK: - Constants

    /// Threshold for flagging expenses that need receipts (IRS documentation)
    private let receiptRequiredThreshold: Decimal = 75.00

    // MARK: - Initialization

    init(service: ExpenseServiceProtocol? = nil) {
        self.service = service
    }

    // MARK: - Computed Properties

    /// Expenses filtered by current filter category
    var filteredExpenses: [Expense] {
        switch filterCategory {
        case .all:
            return expenses
        case .category(let category):
            return expenses.filter { $0.category == category }
        case .group(let group):
            return expenses.filter { $0.category.group == group }
        }
    }

    /// Total amount of all loaded expenses
    var totalExpensesAmount: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Total amount of deductible expenses only
    var totalDeductibleAmount: Decimal {
        expenses.filter { $0.isDeductible }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Total number of expenses
    var expenseCount: Int {
        expenses.count
    }

    /// Expenses grouped by category with totals
    var expensesByCategory: [ExpenseCategory: Decimal] {
        var result: [ExpenseCategory: Decimal] = [:]
        for expense in expenses {
            result[expense.category, default: .zero] += expense.amount
        }
        return result
    }

    /// Unique months from all expenses, sorted descending
    var expenseMonths: [Date] {
        let calendar = Calendar.current
        var uniqueMonths: Set<DateComponents> = []

        for expense in expenses {
            let components = calendar.dateComponents([.year, .month], from: expense.date)
            uniqueMonths.insert(components)
        }

        return uniqueMonths
            .compactMap { calendar.date(from: $0) }
            .sorted(by: >)
    }

    /// Current tax year based on current date
    var currentTaxYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// Unique tax years from all expenses
    var availableTaxYears: [Int] {
        let years = Set(expenses.map { $0.taxYear })
        return years.sorted(by: >)
    }

    /// Expenses that have receipts attached
    var expensesWithReceipts: [Expense] {
        expenses.filter { $0.receipt != nil }
    }

    /// High-value expenses without receipts (>= $75)
    var expensesNeedingReceipts: [Expense] {
        expenses.filter { $0.amount >= receiptRequiredThreshold && $0.receipt == nil }
    }

    /// Check if there are any expenses
    var hasExpenses: Bool {
        !expenses.isEmpty
    }

    // MARK: - Public Methods

    /// Configure service (for cases where service isn't available at init)
    func configure(with service: ExpenseServiceProtocol) {
        self.service = service
    }

    /// Load all expenses from the service
    func loadExpenses() {
        guard let service = service else {
            configureFromContainer()
            return
        }

        isLoading = true
        errorMessage = nil

        expenses = service.fetchAllOrEmpty()

        isLoading = false
    }

    /// Get expenses for a specific month
    func expenses(forMonth month: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }
    }

    /// Add a new expense
    func addExpense(_ expense: Expense) {
        guard let service = service else { return }
        service.create(expense)
        loadExpenses()
    }

    /// Update an existing expense
    func updateExpense(_ expense: Expense) {
        guard let service = service else { return }
        service.update(expense)
        loadExpenses()
    }

    /// Delete an expense
    func deleteExpense(_ expense: Expense) {
        guard let service = service else { return }
        service.delete(expense)
        loadExpenses()
    }

    /// Select an expense for viewing/editing
    func selectExpense(_ expense: Expense) {
        selectedExpense = expense
    }

    /// Clear the current selection
    func clearSelection() {
        selectedExpense = nil
    }

    /// Refresh expenses from the service
    func refresh() {
        loadExpenses()
    }

    // MARK: - Private Methods

    private func configureFromContainer() {
        do {
            service = try ServiceContainer.shared.getExpenseService()
            loadExpenses()
        } catch {
            errorMessage = "Failed to initialize service: \(error.localizedDescription)"
        }
    }
}

// MARK: - Form State

extension ExpenseViewModel {
    /// Check if we have deductible expenses
    var hasDeductibleExpenses: Bool {
        expenses.contains { $0.isDeductible }
    }

    /// Get expense count for a specific category
    func expenseCount(for category: ExpenseCategory) -> Int {
        expenses.filter { $0.category == category }.count
    }

    /// Get expense count for a specific group
    func expenseCount(for group: ExpenseGroup) -> Int {
        expenses.filter { $0.category.group == group }.count
    }

    /// Get total amount for a specific tax year
    func totalAmount(forYear year: Int) -> Decimal {
        expenses.filter { $0.taxYear == year }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    /// Get deductible amount for a specific tax year
    func deductibleAmount(forYear year: Int) -> Decimal {
        expenses.filter { $0.taxYear == year && $0.isDeductible }.reduce(Decimal.zero) { $0 + $1.amount }
    }
}
