//
//  HomeViewModelTests.swift
//  TravelNurseTests
//
//  Unit tests for HomeViewModel
//

import XCTest
import SwiftData
@testable import TravelNurse

final class HomeViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var sut: HomeViewModel!

    @MainActor
    override func setUp() {
        super.setUp()

        // Create in-memory container for testing
        let schema = Schema([
            Assignment.self,
            UserProfile.self,
            Address.self,
            PayBreakdown.self,
            Expense.self,
            Receipt.self,
            MileageTrip.self,
            TaxHomeCompliance.self,
            Document.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            sut = HomeViewModel()
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() {
        sut = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    // MARK: - Greeting Tests

    @MainActor
    func test_greetingText_returnsNonEmptyString() {
        // The greeting should always return a non-empty string
        let greeting = sut.greetingText

        XCTAssertFalse(greeting.isEmpty)
    }

    @MainActor
    func test_greetingText_containsGreetingWord() {
        // The greeting should contain one of the time-based greetings
        let greeting = sut.greetingText

        let validGreetings = ["Good morning", "Good afternoon", "Good evening", "Good night"]
        let containsValidGreeting = validGreetings.contains { greeting.contains($0) }

        XCTAssertTrue(containsValidGreeting, "Greeting '\(greeting)' should contain a valid time-based greeting")
    }

    @MainActor
    func test_greetingText_endsWithComma() {
        // The greeting should end with a comma for the name to follow
        let greeting = sut.greetingText

        XCTAssertTrue(greeting.hasSuffix(","), "Greeting should end with comma")
    }

    // MARK: - Date/Time Tests

    @MainActor
    func test_currentYear_returnsValidYear() {
        // Current year should be reasonable (2024-2030 range for testing)
        let year = sut.currentYear

        XCTAssertGreaterThanOrEqual(year, 2024)
        XCTAssertLessThanOrEqual(year, 2030)
    }

    @MainActor
    func test_currentYear_matchesCalendarYear() {
        // Should match the actual calendar year
        let expectedYear = Calendar.current.component(.year, from: Date())

        XCTAssertEqual(sut.currentYear, expectedYear)
    }

    @MainActor
    func test_currentQuarter_returnsValidQuarter() {
        // Quarter should be Q1, Q2, Q3, or Q4
        let quarter = sut.currentQuarter

        let validQuarters = ["Q1", "Q2", "Q3", "Q4"]
        XCTAssertTrue(validQuarters.contains(quarter), "Quarter '\(quarter)' should be valid")
    }

    @MainActor
    func test_currentQuarter_matchesCalendarMonth() {
        // Quarter should correspond to current month
        let month = Calendar.current.component(.month, from: Date())
        let expectedQuarter: String
        switch month {
        case 1...3: expectedQuarter = "Q1"
        case 4...6: expectedQuarter = "Q2"
        case 7...9: expectedQuarter = "Q3"
        default: expectedQuarter = "Q4"
        }

        XCTAssertEqual(sut.currentQuarter, expectedQuarter)
    }

    // MARK: - Tax Due Date Tests

    @MainActor
    func test_formattedTaxDueDate_returnsNonEmptyString() {
        // Tax due date should always return a formatted date string
        let dueDate = sut.formattedTaxDueDate

        XCTAssertFalse(dueDate.isEmpty)
    }

    @MainActor
    func test_formattedTaxDueDate_containsYear() {
        // The formatted date should contain a year
        let dueDate = sut.formattedTaxDueDate
        let currentYear = Calendar.current.component(.year, from: Date())

        // Should contain current year or next year
        let containsYear = dueDate.contains("\(currentYear)") || dueDate.contains("\(currentYear + 1)")
        XCTAssertTrue(containsYear, "Tax due date '\(dueDate)' should contain a year")
    }

    @MainActor
    func test_formattedTaxDueDate_isValidDateFormat() {
        // Should be in "MMM d, yyyy" format
        let dueDate = sut.formattedTaxDueDate

        // Should contain a comma (indicating "MMM d, yyyy" format)
        XCTAssertTrue(dueDate.contains(","), "Tax due date should be formatted with comma")
    }

    // MARK: - Initial State Tests

    @MainActor
    func test_initialState_ytdIncomeIsZero() {
        XCTAssertEqual(sut.ytdIncome, 0)
    }

    @MainActor
    func test_initialState_ytdDeductionsIsZero() {
        XCTAssertEqual(sut.ytdDeductions, 0)
    }

    @MainActor
    func test_initialState_estimatedTaxDueIsZero() {
        XCTAssertEqual(sut.estimatedTaxDue, 0)
    }

    @MainActor
    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func test_initialState_currentAssignmentIsNil() {
        // No active assignment should be set initially
        XCTAssertNil(sut.currentAssignment)
    }

    @MainActor
    func test_initialState_statesWorkedIsEmpty() {
        XCTAssertTrue(sut.statesWorked.isEmpty)
    }

    @MainActor
    func test_initialState_recentActivitiesIsEmpty() {
        XCTAssertTrue(sut.recentActivities.isEmpty)
    }

    // MARK: - Formatted Properties Tests

    @MainActor
    func test_formattedEstimatedTaxDue_containsDollarSign() {
        let formatted = sut.formattedEstimatedTaxDue

        XCTAssertTrue(formatted.contains("$"))
    }

    @MainActor
    func test_formattedYTDIncome_containsDollarSign() {
        let formatted = sut.formattedYTDIncome

        XCTAssertTrue(formatted.contains("$"))
    }

    @MainActor
    func test_formattedYTDDeductions_containsDollarSign() {
        let formatted = sut.formattedYTDDeductions

        XCTAssertTrue(formatted.contains("$"))
    }

    // MARK: - Assignment Progress Tests

    @MainActor
    func test_assignmentProgress_withNoAssignment_isZero() {
        XCTAssertEqual(sut.assignmentProgress, 0)
    }

    @MainActor
    func test_currentWeekNumber_withNoAssignment_isZero() {
        XCTAssertEqual(sut.currentWeekNumber, 0)
    }

    @MainActor
    func test_totalWeeks_withNoAssignment_isZero() {
        XCTAssertEqual(sut.totalWeeks, 0)
    }

    @MainActor
    func test_formattedWeeklyRate_withNoAssignment_showsZero() {
        let rate = sut.formattedWeeklyRate

        XCTAssertTrue(rate.contains("$0"))
    }

    // MARK: - Income Change Calculation Tests

    @MainActor
    func test_incomeChangePercent_initiallyReturnsNumber() {
        // Income change should return a valid number
        let change = sut.incomeChangePercent

        XCTAssertFalse(change.isNaN)
        XCTAssertFalse(change.isInfinite)
    }

    @MainActor
    func test_isIncomePositive_whenChangeIsPositive_returnsTrue() {
        // When income change percent >= 0, should be positive
        // Note: Initial state has no data, so change is 0 (which is considered positive)
        let isPositive = sut.isIncomePositive

        XCTAssertEqual(isPositive, sut.incomeChangePercent >= 0)
    }

    @MainActor
    func test_isIncomePositive_matchesIncomeChangeSign() {
        let change = sut.incomeChangePercent
        let isPositive = sut.isIncomePositive

        if change >= 0 {
            XCTAssertTrue(isPositive)
        } else {
            XCTAssertFalse(isPositive)
        }
    }

    // MARK: - Trend Data Tests

    @MainActor
    func test_incomeTrendData_returnsSixValues() {
        let trendData = sut.incomeTrendData

        XCTAssertEqual(trendData.count, 6, "Should return 6 months of trend data")
    }

    @MainActor
    func test_incomeTrendData_valuesAreNormalized() {
        let trendData = sut.incomeTrendData

        for value in trendData {
            XCTAssertGreaterThanOrEqual(value, 0.0, "Trend values should be >= 0")
            XCTAssertLessThanOrEqual(value, 1.0, "Trend values should be <= 1")
        }
    }

    @MainActor
    func test_incomeTrendData_hasMinimumVisibility() {
        let trendData = sut.incomeTrendData

        for value in trendData {
            XCTAssertGreaterThanOrEqual(value, 0.1, "Trend values should have minimum visibility of 0.1")
        }
    }

    @MainActor
    func test_deductionsTrendData_returnsSixValues() {
        let trendData = sut.deductionsTrendData

        XCTAssertEqual(trendData.count, 6, "Should return 6 months of trend data")
    }

    @MainActor
    func test_deductionsTrendData_valuesAreNormalized() {
        let trendData = sut.deductionsTrendData

        for value in trendData {
            XCTAssertGreaterThanOrEqual(value, 0.0, "Trend values should be >= 0")
            XCTAssertLessThanOrEqual(value, 1.0, "Trend values should be <= 1")
        }
    }

    // MARK: - Tax Paid Percentage Tests

    @MainActor
    func test_taxPaidPercentage_isBetweenZeroAndOne() {
        let percentage = sut.taxPaidPercentage

        XCTAssertGreaterThanOrEqual(percentage, 0.0)
        XCTAssertLessThanOrEqual(percentage, 1.0)
    }

    @MainActor
    func test_taxPaidPercentage_isNotNaN() {
        let percentage = sut.taxPaidPercentage

        XCTAssertFalse(percentage.isNaN)
    }

    // MARK: - Compliance Badge Tests

    @MainActor
    func test_complianceBadge_returnsNonEmptyString() {
        let badge = sut.complianceBadge

        XCTAssertFalse(badge.isEmpty)
    }

    @MainActor
    func test_complianceBadge_returnsValidBadgeText() {
        let badge = sut.complianceBadge

        let validBadges = ["Excellent", "On Track", "At Risk", "Setup Needed", "Unknown"]
        XCTAssertTrue(validBadges.contains(badge), "Badge '\(badge)' should be a valid badge text")
    }

    @MainActor
    func test_complianceBadgeColor_isNotNil() {
        let color = sut.complianceBadgeColor

        XCTAssertNotNil(color)
    }

    // MARK: - Days Remaining Tests

    @MainActor
    func test_daysRemaining_withNoAssignment_isZero() {
        XCTAssertEqual(sut.daysRemaining, 0)
    }

    @MainActor
    func test_totalDays_withNoAssignment_isZero() {
        XCTAssertEqual(sut.totalDays, 0)
    }

    // MARK: - Assignment Location Tests

    @MainActor
    func test_assignmentLocationName_withNoAssignment_showsDefault() {
        let name = sut.assignmentLocationName

        XCTAssertEqual(name, "No Current Assignment")
    }

    @MainActor
    func test_assignmentState_withNoAssignment_isEmpty() {
        let state = sut.assignmentState

        XCTAssertTrue(state.isEmpty)
    }

    // MARK: - Weekly Rate Tests

    @MainActor
    func test_weeklyRateValue_withNoAssignment_isZero() {
        XCTAssertEqual(sut.weeklyRateValue, 0)
    }

    // MARK: - Tax Due Date Tests

    @MainActor
    func test_taxDueDate_isInFuture() {
        let dueDate = sut.taxDueDate

        // Tax due date should be a future date (or very recent past)
        let thirtyDaysAgo = Date().addingTimeInterval(-86400 * 30)
        XCTAssertGreaterThan(dueDate, thirtyDaysAgo)
    }

    @MainActor
    func test_taxDueDate_isOnThe15th() {
        let dueDate = sut.taxDueDate
        let day = Calendar.current.component(.day, from: dueDate)

        XCTAssertEqual(day, 15, "Tax due dates should be on the 15th")
    }

    // MARK: - YTD Values Tests

    @MainActor
    func test_ytdIncomeValue_matchesYtdIncome() {
        XCTAssertEqual(sut.ytdIncomeValue, sut.ytdIncome)
    }

    @MainActor
    func test_ytdDeductionsValue_matchesYtdDeductions() {
        XCTAssertEqual(sut.ytdDeductionsValue, sut.ytdDeductions)
    }

    @MainActor
    func test_estimatedTaxDueValue_matchesEstimatedTaxDue() {
        XCTAssertEqual(sut.estimatedTaxDueValue, sut.estimatedTaxDue)
    }

    // MARK: - Has Tax Due Tests

    @MainActor
    func test_hasTaxDue_whenZero_returnsFalse() {
        // Initial state has zero tax due
        XCTAssertFalse(sut.hasTaxDue)
    }
}
