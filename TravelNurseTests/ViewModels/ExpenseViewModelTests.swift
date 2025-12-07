//
//  ExpenseViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for ExpenseViewModel
//

import XCTest
@testable import TravelNurse

// MARK: - Mock Expense Service

final class MockExpenseService: ExpenseServiceProtocol {
    var expenses: [Expense] = []
    var createCalled = false
    var updateCalled = false
    var deleteCalled = false
    var lastCreatedExpense: Expense?
    var lastDeletedExpense: Expense?

    func create(_ expense: Expense) -> Result<Void, ServiceError> {
        createCalled = true
        lastCreatedExpense = expense
        expenses.append(expense)
        return .success(())
    }

    func fetchAll() -> Result<[Expense], ServiceError> {
        return .success(expenses.sorted { $0.date > $1.date })
    }

    func fetch(byId id: UUID) -> Result<Expense?, ServiceError> {
        return .success(expenses.first { $0.id == id })
    }

    func fetch(byCategory category: ExpenseCategory) -> Result<[Expense], ServiceError> {
        return .success(expenses.filter { $0.category == category })
    }

    func fetch(byYear year: Int) -> Result<[Expense], ServiceError> {
        return .success(expenses.filter { $0.taxYear == year })
    }

    func fetch(forAssignment assignment: Assignment) -> Result<[Expense], ServiceError> {
        return .success(expenses.filter { $0.assignment?.id == assignment.id })
    }

    func fetchDeductible() -> Result<[Expense], ServiceError> {
        return .success(expenses.filter { $0.isDeductible })
    }

    func fetchRecent(limit: Int) -> Result<[Expense], ServiceError> {
        let sorted = expenses.sorted { $0.date > $1.date }
        return .success(Array(sorted.prefix(limit)))
    }

    func update(_ expense: Expense) -> Result<Void, ServiceError> {
        updateCalled = true
        return .success(())
    }

    func delete(_ expense: Expense) -> Result<Void, ServiceError> {
        deleteCalled = true
        lastDeletedExpense = expense
        expenses.removeAll { $0.id == expense.id }
        return .success(())
    }

    func totalExpenses(forYear year: Int) -> Decimal {
        return fetchByYearOrEmpty(year).reduce(Decimal.zero) { $0 + $1.amount }
    }

    func totalDeductible(forYear year: Int) -> Decimal {
        return fetchByYearOrEmpty(year).filter { $0.isDeductible }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    func expensesByCategory(forYear year: Int) -> [ExpenseCategory: Decimal] {
        var result: [ExpenseCategory: Decimal] = [:]
        for expense in fetchByYearOrEmpty(year) {
            result[expense.category, default: .zero] += expense.amount
        }
        return result
    }
}

// MARK: - Test Helpers

extension Expense {
    static func testExpense(
        category: ExpenseCategory = .meals,
        amount: Decimal = 25.00,
        date: Date = Date(),
        merchantName: String? = "Test Merchant",
        isDeductible: Bool = true
    ) -> Expense {
        Expense(
            category: category,
            amount: amount,
            date: date,
            merchantName: merchantName,
            isDeductible: isDeductible
        )
    }
}

// MARK: - Test Cases

@MainActor
final class ExpenseViewModelTests: XCTestCase {

    var sut: ExpenseViewModel!
    var mockService: MockExpenseService!

    override func setUp() {
        super.setUp()
        mockService = MockExpenseService()
        sut = ExpenseViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_setsDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.filterCategory, .all)
        XCTAssertNil(sut.selectedExpense)
        XCTAssertFalse(sut.showingAddSheet)
        XCTAssertTrue(sut.expenses.isEmpty)
    }

    // MARK: - Load Expenses Tests

    func testLoadExpenses_populatesExpensesArray() {
        // Given
        let expense1 = Expense.testExpense(category: .meals, amount: 25.00)
        let expense2 = Expense.testExpense(category: .gasoline, amount: 45.00)
        mockService.expenses = [expense1, expense2]

        // When
        sut.loadExpenses()

        // Then
        XCTAssertEqual(sut.expenses.count, 2)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadExpenses_returnsExpensesSortedByDateDescending() {
        // Given
        let oldExpense = Expense.testExpense(
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        )
        let recentExpense = Expense.testExpense(date: Date())
        mockService.expenses = [oldExpense, recentExpense]

        // When
        sut.loadExpenses()

        // Then
        XCTAssertEqual(sut.expenses.first?.date, recentExpense.date)
    }

    // MARK: - Filter Tests

    func testFilterCategory_all_returnsAllExpenses() {
        // Given
        let mealExpense = Expense.testExpense(category: .meals)
        let gasExpense = Expense.testExpense(category: .gasoline)
        mockService.expenses = [mealExpense, gasExpense]
        sut.loadExpenses()

        // When
        sut.filterCategory = .all

        // Then
        XCTAssertEqual(sut.filteredExpenses.count, 2)
    }

    func testFilterCategory_specific_returnsOnlyMatchingCategory() {
        // Given
        let mealExpense1 = Expense.testExpense(category: .meals)
        let mealExpense2 = Expense.testExpense(category: .meals)
        let gasExpense = Expense.testExpense(category: .gasoline)
        mockService.expenses = [mealExpense1, mealExpense2, gasExpense]
        sut.loadExpenses()

        // When
        sut.filterCategory = .category(.meals)

        // Then
        XCTAssertEqual(sut.filteredExpenses.count, 2)
        XCTAssertTrue(sut.filteredExpenses.allSatisfy { $0.category == .meals })
    }

    func testFilterCategory_byGroup_returnsMatchingGroupCategories() {
        // Given
        let mealExpense = Expense.testExpense(category: .meals)
        let groceryExpense = Expense.testExpense(category: .groceries)
        let gasExpense = Expense.testExpense(category: .gasoline)
        mockService.expenses = [mealExpense, groceryExpense, gasExpense]
        sut.loadExpenses()

        // When
        sut.filterCategory = .group(.meals) // meals group includes meals and groceries

        // Then
        XCTAssertEqual(sut.filteredExpenses.count, 2)
    }

    // MARK: - CRUD Tests

    func testAddExpense_callsServiceCreate() {
        // Given
        let expense = Expense.testExpense()

        // When
        sut.addExpense(expense)

        // Then
        XCTAssertTrue(mockService.createCalled)
        XCTAssertEqual(mockService.lastCreatedExpense?.id, expense.id)
    }

    func testUpdateExpense_callsServiceUpdate() {
        // Given
        let expense = Expense.testExpense()
        mockService.expenses = [expense]

        // When
        sut.updateExpense(expense)

        // Then
        XCTAssertTrue(mockService.updateCalled)
    }

    func testDeleteExpense_callsServiceDelete() {
        // Given
        let expense = Expense.testExpense()
        mockService.expenses = [expense]

        // When
        sut.deleteExpense(expense)

        // Then
        XCTAssertTrue(mockService.deleteCalled)
        XCTAssertEqual(mockService.lastDeletedExpense?.id, expense.id)
    }

    // MARK: - Selection Tests

    func testSelectExpense_setsSelectedExpense() {
        // Given
        let expense = Expense.testExpense()
        mockService.expenses = [expense]
        sut.loadExpenses()

        // When
        sut.selectExpense(expense)

        // Then
        XCTAssertEqual(sut.selectedExpense?.id, expense.id)
    }

    func testClearSelection_clearsSelectedExpense() {
        // Given
        let expense = Expense.testExpense()
        sut.selectExpense(expense)

        // When
        sut.clearSelection()

        // Then
        XCTAssertNil(sut.selectedExpense)
    }

    // MARK: - Statistics Tests

    func testTotalExpenses_calculatesCorrectSum() {
        // Given
        let expense1 = Expense.testExpense(amount: 100.00)
        let expense2 = Expense.testExpense(amount: 50.00)
        let expense3 = Expense.testExpense(amount: 25.50)
        mockService.expenses = [expense1, expense2, expense3]
        sut.loadExpenses()

        // Then
        XCTAssertEqual(sut.totalExpensesAmount, Decimal(175.50))
    }

    func testTotalDeductible_calculatesOnlyDeductibleExpenses() {
        // Given
        let deductible1 = Expense.testExpense(amount: 100.00, isDeductible: true)
        let deductible2 = Expense.testExpense(amount: 50.00, isDeductible: true)
        let nonDeductible = Expense.testExpense(amount: 25.00, isDeductible: false)
        mockService.expenses = [deductible1, deductible2, nonDeductible]
        sut.loadExpenses()

        // Then
        XCTAssertEqual(sut.totalDeductibleAmount, Decimal(150.00))
    }

    func testExpenseCount_returnsCorrectCount() {
        // Given
        let expense1 = Expense.testExpense()
        let expense2 = Expense.testExpense()
        let expense3 = Expense.testExpense()
        mockService.expenses = [expense1, expense2, expense3]
        sut.loadExpenses()

        // Then
        XCTAssertEqual(sut.expenseCount, 3)
    }

    func testExpensesByCategory_groupsCorrectly() {
        // Given
        let meal1 = Expense.testExpense(category: .meals, amount: 20.00)
        let meal2 = Expense.testExpense(category: .meals, amount: 30.00)
        let gas = Expense.testExpense(category: .gasoline, amount: 50.00)
        mockService.expenses = [meal1, meal2, gas]
        sut.loadExpenses()

        // Then
        let categoryTotals = sut.expensesByCategory
        XCTAssertEqual(categoryTotals[.meals], Decimal(50.00))
        XCTAssertEqual(categoryTotals[.gasoline], Decimal(50.00))
    }

    // MARK: - Date Grouping Tests

    func testExpenseMonths_returnsUniqueMonthsSorted() {
        // Given
        let january = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let february = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 10))!
        let marchEarly = Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 5))!
        let marchLate = Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 25))!

        let expense1 = Expense.testExpense(date: january)
        let expense2 = Expense.testExpense(date: february)
        let expense3 = Expense.testExpense(date: marchEarly)
        let expense4 = Expense.testExpense(date: marchLate)
        mockService.expenses = [expense1, expense2, expense3, expense4]
        sut.loadExpenses()

        // Then
        let months = sut.expenseMonths
        XCTAssertEqual(months.count, 3) // Jan, Feb, March (unique months)
    }

    func testExpenses_forMonth_returnsCorrectExpenses() {
        // Given
        let january = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let february = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 10))!

        let janExpense = Expense.testExpense(date: january)
        let febExpense1 = Expense.testExpense(date: february)
        let febExpense2 = Expense.testExpense(date: february)
        mockService.expenses = [janExpense, febExpense1, febExpense2]
        sut.loadExpenses()

        // Then
        let febExpenses = sut.expenses(forMonth: february)
        XCTAssertEqual(febExpenses.count, 2)
    }

    // MARK: - Tax Year Tests

    func testCurrentTaxYear_returnsCurrentYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(sut.currentTaxYear, currentYear)
    }

    func testAvailableTaxYears_returnsYearsFromExpenses() {
        // Given
        let year2023 = Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 1))!
        let year2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1))!

        let expense2023 = Expense.testExpense(date: year2023)
        let expense2024 = Expense.testExpense(date: year2024)
        mockService.expenses = [expense2023, expense2024]
        sut.loadExpenses()

        // Then
        XCTAssertTrue(sut.availableTaxYears.contains(2023))
        XCTAssertTrue(sut.availableTaxYears.contains(2024))
    }

    // MARK: - Receipt Status Tests

    func testExpensesWithReceipts_returnsOnlyExpensesWithReceipts() {
        // Given
        let withReceipt = Expense.testExpense()
        withReceipt.receipt = Receipt(imageData: Data())

        let withoutReceipt = Expense.testExpense()

        mockService.expenses = [withReceipt, withoutReceipt]
        sut.loadExpenses()

        // Then
        XCTAssertEqual(sut.expensesWithReceipts.count, 1)
    }

    func testExpensesNeedingReceipts_returnsHighValueExpensesWithoutReceipts() {
        // Given
        let highValueNoReceipt = Expense.testExpense(amount: 100.00)
        let lowValueNoReceipt = Expense.testExpense(amount: 10.00)
        let highValueWithReceipt = Expense.testExpense(amount: 150.00)
        highValueWithReceipt.receipt = Receipt(imageData: Data())

        mockService.expenses = [highValueNoReceipt, lowValueNoReceipt, highValueWithReceipt]
        sut.loadExpenses()

        // Then - expenses >= $75 without receipt should be flagged
        let needingReceipts = sut.expensesNeedingReceipts
        XCTAssertTrue(needingReceipts.contains { $0.id == highValueNoReceipt.id })
        XCTAssertFalse(needingReceipts.contains { $0.id == lowValueNoReceipt.id })
        XCTAssertFalse(needingReceipts.contains { $0.id == highValueWithReceipt.id })
    }

    // MARK: - Refresh Tests

    func testRefresh_reloadsExpenses() {
        // Given
        let expense = Expense.testExpense()
        mockService.expenses = [expense]
        sut.loadExpenses()
        XCTAssertEqual(sut.expenses.count, 1)

        // When - add another expense externally
        let newExpense = Expense.testExpense()
        mockService.expenses.append(newExpense)
        sut.refresh()

        // Then
        XCTAssertEqual(sut.expenses.count, 2)
    }

    // MARK: - Empty State Tests

    func testHasExpenses_returnsFalse_whenEmpty() {
        XCTAssertFalse(sut.hasExpenses)
    }

    func testHasExpenses_returnsTrue_whenNotEmpty() {
        // Given
        mockService.expenses = [Expense.testExpense()]
        sut.loadExpenses()

        // Then
        XCTAssertTrue(sut.hasExpenses)
    }
}

// MARK: - ExpenseFilterCategory Tests

@MainActor
final class ExpenseFilterCategoryTests: XCTestCase {

    func testAll_displayName() {
        XCTAssertEqual(ExpenseFilterCategory.all.displayName, "All")
    }

    func testCategory_displayName() {
        let filter = ExpenseFilterCategory.category(.meals)
        XCTAssertEqual(filter.displayName, "Meals")
    }

    func testGroup_displayName() {
        let filter = ExpenseFilterCategory.group(.transportation)
        XCTAssertEqual(filter.displayName, "Transportation")
    }
}
