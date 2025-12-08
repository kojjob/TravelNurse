//
//  RecurringExpenseTests.swift
//  TravelNurseTests
//
//  TDD tests for RecurringExpense model - written BEFORE implementation
//

import XCTest
import SwiftData
@testable import TravelNurse

// MARK: - RecurrenceFrequency Tests

final class RecurrenceFrequencyTests: XCTestCase {

    func test_weekly_displayName() {
        XCTAssertEqual(RecurrenceFrequency.weekly.displayName, "Weekly")
    }

    func test_biweekly_displayName() {
        XCTAssertEqual(RecurrenceFrequency.biweekly.displayName, "Every 2 Weeks")
    }

    func test_monthly_displayName() {
        XCTAssertEqual(RecurrenceFrequency.monthly.displayName, "Monthly")
    }

    func test_quarterly_displayName() {
        XCTAssertEqual(RecurrenceFrequency.quarterly.displayName, "Quarterly")
    }

    func test_annually_displayName() {
        XCTAssertEqual(RecurrenceFrequency.annually.displayName, "Annually")
    }

    func test_weekly_calendarComponent() {
        XCTAssertEqual(RecurrenceFrequency.weekly.calendarComponent, .weekOfYear)
    }

    func test_monthly_calendarComponent() {
        XCTAssertEqual(RecurrenceFrequency.monthly.calendarComponent, .month)
    }

    func test_annually_calendarComponent() {
        XCTAssertEqual(RecurrenceFrequency.annually.calendarComponent, .year)
    }

    func test_weekly_componentValue() {
        XCTAssertEqual(RecurrenceFrequency.weekly.componentValue, 1)
    }

    func test_biweekly_componentValue() {
        XCTAssertEqual(RecurrenceFrequency.biweekly.componentValue, 2)
    }

    func test_quarterly_componentValue() {
        XCTAssertEqual(RecurrenceFrequency.quarterly.componentValue, 3)
    }
}

// MARK: - RecurringExpense Model Tests

final class RecurringExpenseModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_setsCorrectValues() {
        let startDate = Date()
        let recurring = RecurringExpense(
            name: "Monthly Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: startDate,
            merchantName: "Property Management"
        )

        XCTAssertEqual(recurring.name, "Monthly Rent")
        XCTAssertEqual(recurring.category, .rent)
        XCTAssertEqual(recurring.amount, 1500)
        XCTAssertEqual(recurring.frequency, .monthly)
        XCTAssertEqual(recurring.startDate, startDate)
        XCTAssertEqual(recurring.merchantName, "Property Management")
        XCTAssertTrue(recurring.isActive)
        XCTAssertNil(recurring.endDate)
    }

    func test_init_defaultsToActive() {
        let recurring = makeRecurringExpense()

        XCTAssertTrue(recurring.isActive)
    }

    func test_init_defaultsToDeductible() {
        let recurring = makeRecurringExpense()

        XCTAssertTrue(recurring.isDeductible)
    }

    // MARK: - Next Occurrence Tests

    func test_nextOccurrence_weekly_calculatesCorrectly() {
        let startDate = makeDate(year: 2025, month: 1, day: 1)
        let recurring = makeRecurringExpense(
            frequency: .weekly,
            startDate: startDate,
            lastGeneratedDate: startDate
        )

        let next = recurring.nextOccurrence

        XCTAssertNotNil(next)
        let expected = makeDate(year: 2025, month: 1, day: 8)
        XCTAssertEqual(Calendar.current.startOfDay(for: next!), Calendar.current.startOfDay(for: expected))
    }

    func test_nextOccurrence_monthly_calculatesCorrectly() {
        let startDate = makeDate(year: 2025, month: 1, day: 15)
        let recurring = makeRecurringExpense(
            frequency: .monthly,
            startDate: startDate,
            lastGeneratedDate: startDate
        )

        let next = recurring.nextOccurrence

        XCTAssertNotNil(next)
        let components = Calendar.current.dateComponents([.month, .day], from: next!)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 15)
    }

    func test_nextOccurrence_whenInactive_returnsNil() {
        let recurring = makeRecurringExpense(isActive: false)

        XCTAssertNil(recurring.nextOccurrence)
    }

    func test_nextOccurrence_afterEndDate_returnsNil() {
        let startDate = makeDate(year: 2025, month: 1, day: 1)
        let endDate = makeDate(year: 2025, month: 1, day: 15)
        let recurring = makeRecurringExpense(
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            lastGeneratedDate: startDate
        )

        // Next would be Feb 1, but end date is Jan 15
        XCTAssertNil(recurring.nextOccurrence)
    }

    func test_nextOccurrence_noLastGenerated_returnsStartDate() {
        let startDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let recurring = makeRecurringExpense(
            startDate: startDate,
            lastGeneratedDate: nil
        )

        XCTAssertEqual(recurring.nextOccurrence, startDate)
    }

    // MARK: - Is Due Tests

    func test_isDue_whenNextOccurrenceIsToday_returnsTrue() {
        let today = Calendar.current.startOfDay(for: Date())
        let recurring = makeRecurringExpense(
            startDate: today,
            lastGeneratedDate: nil
        )

        XCTAssertTrue(recurring.isDue)
    }

    func test_isDue_whenNextOccurrenceIsPast_returnsTrue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recurring = makeRecurringExpense(
            startDate: pastDate,
            lastGeneratedDate: nil
        )

        XCTAssertTrue(recurring.isDue)
    }

    func test_isDue_whenNextOccurrenceIsFuture_returnsFalse() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let recurring = makeRecurringExpense(
            startDate: futureDate,
            lastGeneratedDate: nil
        )

        XCTAssertFalse(recurring.isDue)
    }

    func test_isDue_whenInactive_returnsFalse() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recurring = makeRecurringExpense(
            startDate: pastDate,
            isActive: false
        )

        XCTAssertFalse(recurring.isDue)
    }

    // MARK: - Total Generated Tests

    func test_totalGenerated_calculatesCorrectly() {
        let recurring = makeRecurringExpense(amount: 100)
        recurring.generatedCount = 5

        XCTAssertEqual(recurring.totalGenerated, 500)
    }

    func test_totalGenerated_whenZeroCount_returnsZero() {
        let recurring = makeRecurringExpense(amount: 100)
        recurring.generatedCount = 0

        XCTAssertEqual(recurring.totalGenerated, 0)
    }

    // MARK: - Formatted Properties Tests

    func test_frequencyDescription_returnsCorrectString() {
        let recurring = makeRecurringExpense(frequency: .monthly, amount: 1500)

        XCTAssertTrue(recurring.frequencyDescription.contains("Monthly"))
    }

    // MARK: - Pause/Resume Tests

    func test_pause_setsInactive() {
        let recurring = makeRecurringExpense(isActive: true)

        recurring.pause()

        XCTAssertFalse(recurring.isActive)
    }

    func test_resume_setsActive() {
        let recurring = makeRecurringExpense(isActive: false)

        recurring.resume()

        XCTAssertTrue(recurring.isActive)
    }

    // MARK: - Helpers

    private func makeRecurringExpense(
        name: String = "Test Expense",
        category: ExpenseCategory = .rent,
        amount: Decimal = 1000,
        frequency: RecurrenceFrequency = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil,
        merchantName: String? = nil,
        isActive: Bool = true,
        lastGeneratedDate: Date? = nil
    ) -> RecurringExpense {
        let expense = RecurringExpense(
            name: name,
            category: category,
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            merchantName: merchantName
        )
        expense.endDate = endDate
        expense.isActive = isActive
        expense.lastGeneratedDate = lastGeneratedDate
        return expense
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
