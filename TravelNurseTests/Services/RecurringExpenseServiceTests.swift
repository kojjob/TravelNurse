//
//  RecurringExpenseServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for RecurringExpenseService - written BEFORE implementation
//

import XCTest
import SwiftData
@testable import TravelNurse

@MainActor
final class RecurringExpenseServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var sut: RecurringExpenseService!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            RecurringExpense.self,
            Expense.self,
            UserProfile.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            sut = RecurringExpenseService(modelContext: modelContext)
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Create Tests

    func test_create_insertsIntoContext() {
        let recurring = sut.create(
            name: "Monthly Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date(),
            merchantName: "Landlord"
        )

        XCTAssertNotNil(recurring)
        XCTAssertEqual(recurring.name, "Monthly Rent")

        let fetched = sut.fetchAll()
        XCTAssertEqual(fetched.count, 1)
    }

    func test_create_setsDefaultValues() {
        let recurring = sut.create(
            name: "Phone Bill",
            category: .cellPhone,
            amount: 80,
            frequency: .monthly,
            startDate: Date()
        )

        XCTAssertTrue(recurring.isActive)
        XCTAssertTrue(recurring.isDeductible)
        XCTAssertEqual(recurring.generatedCount, 0)
    }

    // MARK: - Fetch Tests

    func test_fetchAll_returnsAllRecurring() {
        _ = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: Date())
        _ = sut.create(name: "Phone", category: .cellPhone, amount: 80, frequency: .monthly, startDate: Date())
        _ = sut.create(name: "Internet", category: .internet, amount: 60, frequency: .monthly, startDate: Date())

        let all = sut.fetchAll()

        XCTAssertEqual(all.count, 3)
    }

    func test_fetchActive_returnsOnlyActive() {
        let active = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: Date())
        let inactive = sut.create(name: "Phone", category: .cellPhone, amount: 80, frequency: .monthly, startDate: Date())
        inactive.isActive = false

        let fetched = sut.fetchActive()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, active.id)
    }

    func test_fetchDue_returnsOnlyDueExpenses() {
        let pastStart = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let futureStart = Calendar.current.date(byAdding: .month, value: 1, to: Date())!

        let due = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: pastStart)
        _ = sut.create(name: "Future", category: .cellPhone, amount: 80, frequency: .monthly, startDate: futureStart)

        let fetched = sut.fetchDue()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, due.id)
    }

    func test_fetchByCategory_filtersCorrectly() {
        _ = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: Date())
        _ = sut.create(name: "Phone", category: .cellPhone, amount: 80, frequency: .monthly, startDate: Date())
        _ = sut.create(name: "Internet", category: .internet, amount: 60, frequency: .monthly, startDate: Date())

        let cellPhoneExpenses = sut.fetchByCategory(.cellPhone)

        XCTAssertEqual(cellPhoneExpenses.count, 1)
        XCTAssertEqual(cellPhoneExpenses.first?.name, "Phone")
    }

    // MARK: - Generate Expense Tests

    func test_generateExpense_createsExpenseRecord() {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recurring = sut.create(
            name: "Monthly Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: startDate,
            merchantName: "Landlord"
        )

        let expense = sut.generateExpense(from: recurring)

        XCTAssertNotNil(expense)
        XCTAssertEqual(expense?.category, .rent)
        XCTAssertEqual(expense?.amount, 1500)
        XCTAssertEqual(expense?.merchantName, "Landlord")
    }

    func test_generateExpense_incrementsCount() {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: startDate
        )

        _ = sut.generateExpense(from: recurring)

        XCTAssertEqual(recurring.generatedCount, 1)
    }

    func test_generateExpense_updatesLastGeneratedDate() {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: startDate
        )

        _ = sut.generateExpense(from: recurring)

        XCTAssertNotNil(recurring.lastGeneratedDate)
    }

    func test_generateExpense_whenNotDue_returnsNil() {
        let futureStart = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let recurring = sut.create(
            name: "Future Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: futureStart
        )

        let expense = sut.generateExpense(from: recurring)

        XCTAssertNil(expense)
    }

    func test_generateExpense_whenInactive_returnsNil() {
        let startDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: startDate
        )
        recurring.isActive = false

        let expense = sut.generateExpense(from: recurring)

        XCTAssertNil(expense)
    }

    // MARK: - Process All Due Tests

    func test_processAllDue_generatesMultipleExpenses() {
        let pastDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!

        _ = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: pastDate)
        _ = sut.create(name: "Phone", category: .cellPhone, amount: 80, frequency: .monthly, startDate: pastDate)

        let generated = sut.processAllDue()

        XCTAssertEqual(generated.count, 2)
    }

    func test_processAllDue_skipsNotDue() {
        let pastDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!

        _ = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: pastDate)
        _ = sut.create(name: "Future", category: .cellPhone, amount: 80, frequency: .monthly, startDate: futureDate)

        let generated = sut.processAllDue()

        XCTAssertEqual(generated.count, 1)
    }

    // MARK: - Update Tests

    func test_update_changesAmount() {
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date()
        )

        sut.update(recurring, amount: 1600)

        XCTAssertEqual(recurring.amount, 1600)
    }

    func test_update_changesFrequency() {
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date()
        )

        sut.update(recurring, frequency: .weekly)

        XCTAssertEqual(recurring.frequency, .weekly)
    }

    // MARK: - Delete Tests

    func test_delete_removesFromContext() {
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date()
        )

        sut.delete(recurring)

        let all = sut.fetchAll()
        XCTAssertEqual(all.count, 0)
    }

    // MARK: - Pause/Resume Tests

    func test_pause_deactivatesRecurring() {
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date()
        )

        sut.pause(recurring)

        XCTAssertFalse(recurring.isActive)
    }

    func test_resume_activatesRecurring() {
        let recurring = sut.create(
            name: "Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date()
        )
        recurring.isActive = false

        sut.resume(recurring)

        XCTAssertTrue(recurring.isActive)
    }

    // MARK: - Summary Tests

    func test_monthlySummary_calculatesCorrectTotal() {
        _ = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: Date())
        _ = sut.create(name: "Phone", category: .cellPhone, amount: 80, frequency: .monthly, startDate: Date())
        _ = sut.create(name: "Internet", category: .internet, amount: 60, frequency: .monthly, startDate: Date())

        let summary = sut.monthlySummary()

        // All are monthly, so monthly total = 1500 + 80 + 60 = 1640
        XCTAssertEqual(summary.monthlyTotal, 1640)
    }

    func test_monthlySummary_convertsWeeklyToMonthly() {
        _ = sut.create(name: "Weekly Expense", category: .meals, amount: 100, frequency: .weekly, startDate: Date())

        let summary = sut.monthlySummary()

        // Weekly * ~4.33 weeks per month ≈ 433
        XCTAssertGreaterThan(summary.monthlyTotal, 400)
        XCTAssertLessThan(summary.monthlyTotal, 450)
    }

    func test_monthlySummary_countsActiveOnly() {
        _ = sut.create(name: "Rent", category: .rent, amount: 1500, frequency: .monthly, startDate: Date())
        let inactive = sut.create(name: "Phone", category: .cellPhone, amount: 80, frequency: .monthly, startDate: Date())
        inactive.isActive = false

        let summary = sut.monthlySummary()

        XCTAssertEqual(summary.activeCount, 1)
    }
}
