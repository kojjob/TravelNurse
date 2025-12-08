//
//  TaxesViewModelTests.swift
//  TravelNurseTests
//
//  Unit tests for TaxesViewModel
//

import XCTest
import SwiftData
@testable import TravelNurse

final class TaxesViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var sut: TaxesViewModel!

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
            sut = TaxesViewModel()
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

    // MARK: - Initial State Tests

    @MainActor
    func test_initialState_totalEstimatedTaxIsZero() {
        XCTAssertEqual(sut.totalEstimatedTax, 0)
    }

    @MainActor
    func test_initialState_totalPaidTaxIsZero() {
        XCTAssertEqual(sut.totalPaidTax, 0)
    }

    @MainActor
    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func test_initialState_errorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func test_initialState_quarterlyTaxesIsEmpty() {
        XCTAssertTrue(sut.quarterlyTaxes.isEmpty)
    }

    @MainActor
    func test_initialState_showErrorIsFalse() {
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Remaining Tax Calculation Tests

    @MainActor
    func test_remainingTax_whenBothZero_returnsZero() {
        // Initial state: both are zero
        let remaining = sut.remainingTax

        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Payment Progress Tests

    @MainActor
    func test_paymentProgress_whenZeroEstimate_returnsZero() {
        // Initial state: zero estimated tax
        let progress = sut.paymentProgress

        XCTAssertEqual(progress, 0.0)
    }

    @MainActor
    func test_paymentProgress_isWithinValidRange() {
        // Progress should always be between 0 and 1
        let progress = sut.paymentProgress

        XCTAssertGreaterThanOrEqual(progress, 0.0)
        XCTAssertLessThanOrEqual(progress, 1.0)
    }

    // MARK: - Quarter Name Tests

    @MainActor
    func test_currentQuarterName_returnsValidQuarter() {
        // Quarter name should be Q1, Q2, Q3, or Q4
        let quarterName = sut.currentQuarterName

        let validQuarters = ["Q1", "Q2", "Q3", "Q4"]
        XCTAssertTrue(validQuarters.contains(quarterName), "Quarter name should be valid: \(quarterName)")
    }

    @MainActor
    func test_currentQuarterName_matchesCurrentMonth() {
        // Given
        let month = Calendar.current.component(.month, from: Date())
        let expectedQuarter: String
        switch month {
        case 1...3: expectedQuarter = "Q1"
        case 4...6: expectedQuarter = "Q2"
        case 7...9: expectedQuarter = "Q3"
        default: expectedQuarter = "Q4"
        }

        // When
        let quarterName = sut.currentQuarterName

        // Then
        XCTAssertEqual(quarterName, expectedQuarter)
    }

    // MARK: - QuarterStatus Enum Tests

    @MainActor
    func test_quarterStatus_paidExists() {
        let status: QuarterStatus = .paid
        XCTAssertNotNil(status)
        XCTAssertEqual(status.displayName, "Paid")
    }

    @MainActor
    func test_quarterStatus_overdueExists() {
        let status: QuarterStatus = .overdue
        XCTAssertNotNil(status)
        XCTAssertEqual(status.displayName, "Overdue")
    }

    @MainActor
    func test_quarterStatus_dueSoonExists() {
        let status: QuarterStatus = .dueSoon
        XCTAssertNotNil(status)
        XCTAssertEqual(status.displayName, "Due Soon")
    }

    @MainActor
    func test_quarterStatus_upcomingExists() {
        let status: QuarterStatus = .upcoming
        XCTAssertNotNil(status)
        XCTAssertEqual(status.displayName, "Upcoming")
    }

    @MainActor
    func test_quarterStatus_hasValidIconNames() {
        let allStatuses: [QuarterStatus] = [.paid, .overdue, .dueSoon, .upcoming]

        for status in allStatuses {
            XCTAssertFalse(status.iconName.isEmpty, "\(status.displayName) should have a valid icon name")
        }
    }

    // MARK: - Error Handling Tests

    @MainActor
    func test_dismissError_setsShowErrorToFalse() {
        // Given
        sut.showError = true

        // When
        sut.dismissError()

        // Then
        XCTAssertFalse(sut.showError)
    }

    @MainActor
    func test_dismissError_clearsErrorMessage() {
        // Given - showError was set to true
        sut.showError = true

        // When
        sut.dismissError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Year Selection Tests

    @MainActor
    func test_selectedYear_defaultsToCurrentYear() {
        let currentYear = Calendar.current.component(.year, from: Date())

        XCTAssertEqual(sut.selectedYear, currentYear)
    }

    @MainActor
    func test_selectedYear_canBeChanged() {
        // Given
        let previousYear = Calendar.current.component(.year, from: Date()) - 1

        // When
        sut.selectedYear = previousYear

        // Then
        XCTAssertEqual(sut.selectedYear, previousYear)
    }

    // MARK: - Formatted Properties Tests

    @MainActor
    func test_formattedRemainingTax_containsDollarSign() {
        let formatted = sut.formattedRemainingTax

        XCTAssertTrue(formatted.contains("$"))
    }

    @MainActor
    func test_formattedTotalEstimatedTax_containsDollarSign() {
        let formatted = sut.formattedTotalEstimatedTax

        XCTAssertTrue(formatted.contains("$"))
    }

    @MainActor
    func test_formattedTotalPaidTax_containsDollarSign() {
        let formatted = sut.formattedTotalPaidTax

        XCTAssertTrue(formatted.contains("$"))
    }

    // MARK: - Next Due Quarter Tests

    @MainActor
    func test_nextDueQuarter_initiallyNil() {
        // With no quarterly taxes loaded, next due should be nil
        XCTAssertNil(sut.nextDueQuarter)
    }

    @MainActor
    func test_daysUntilNextPayment_initiallyNil() {
        // With no quarterly taxes loaded, days until payment should be nil
        XCTAssertNil(sut.daysUntilNextPayment)
    }

    // MARK: - QuarterlyTax Struct Tests

    @MainActor
    func test_quarterlyTax_statusCalculation_paid() {
        // Given
        let tax = QuarterlyTax(
            quarter: "Q1",
            year: 2025,
            dueDate: Date().addingTimeInterval(-86400), // yesterday
            estimatedAmount: 1000,
            paidAmount: 1000,
            isPaid: true,
            paidDate: Date().addingTimeInterval(-86400)
        )

        // Then
        XCTAssertEqual(tax.status, .paid)
    }

    @MainActor
    func test_quarterlyTax_statusCalculation_overdue() {
        // Given - not paid and due date is in the past
        let tax = QuarterlyTax(
            quarter: "Q1",
            year: 2024,
            dueDate: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            estimatedAmount: 1000,
            paidAmount: 0,
            isPaid: false,
            paidDate: nil
        )

        // Then
        XCTAssertEqual(tax.status, .overdue)
    }

    @MainActor
    func test_quarterlyTax_statusCalculation_upcoming() {
        // Given - not paid and due date is far in the future
        let tax = QuarterlyTax(
            quarter: "Q4",
            year: 2025,
            dueDate: Date().addingTimeInterval(86400 * 90), // 90 days from now
            estimatedAmount: 1000,
            paidAmount: 0,
            isPaid: false,
            paidDate: nil
        )

        // Then
        XCTAssertEqual(tax.status, .upcoming)
    }

    @MainActor
    func test_quarterlyTax_remainingAmount_calculatesCorrectly() {
        // Given
        let tax = QuarterlyTax(
            quarter: "Q1",
            year: 2025,
            dueDate: Date(),
            estimatedAmount: 1000,
            paidAmount: 300,
            isPaid: false,
            paidDate: nil
        )

        // Then
        XCTAssertEqual(tax.remainingAmount, 700)
    }

    @MainActor
    func test_quarterlyTax_formattedDueDate_isNotEmpty() {
        // Given
        let tax = QuarterlyTax(
            quarter: "Q1",
            year: 2025,
            dueDate: Date(),
            estimatedAmount: 1000,
            paidAmount: 0,
            isPaid: false,
            paidDate: nil
        )

        // Then
        XCTAssertFalse(tax.formattedDueDate.isEmpty)
    }

    // MARK: - Chart Segments Tests

    @MainActor
    func test_chartSegments_initiallyEmpty() {
        // Initial state with no tax breakdown
        XCTAssertTrue(sut.chartSegments.isEmpty)
    }

    @MainActor
    func test_chartSegments_matchesTaxBreakdownCount() {
        // The number of chart segments should equal the number of tax breakdown items
        XCTAssertEqual(sut.chartSegments.count, sut.taxBreakdown.count)
    }

    @MainActor
    func test_formattedEffectiveTaxRate_initiallyZero() {
        // With no income, effective rate should be 0%
        let rate = sut.formattedEffectiveTaxRate
        XCTAssertEqual(rate, "0%")
    }

    @MainActor
    func test_formattedEffectiveTaxRate_containsPercentSign() {
        let rate = sut.formattedEffectiveTaxRate
        XCTAssertTrue(rate.contains("%"))
    }
}

// MARK: - ChartSegment Tests

final class ChartSegmentTests: XCTestCase {

    func test_chartSegment_formattedValue_containsDollarSign() {
        // Given
        let segment = ChartSegment(
            label: "Federal",
            value: 10000,
            color: TNColors.primary,
            percentage: 0.5
        )

        // Then
        XCTAssertTrue(segment.formattedValue.contains("$"))
    }

    func test_chartSegment_formattedPercentage_containsPercentSign() {
        // Given
        let segment = ChartSegment(
            label: "Federal",
            value: 10000,
            color: TNColors.primary,
            percentage: 0.5
        )

        // Then
        XCTAssertTrue(segment.formattedPercentage.contains("%"))
    }

    func test_chartSegment_formattedPercentage_displaysCorrectValue() {
        // Given
        let segment = ChartSegment(
            label: "Federal",
            value: 10000,
            color: TNColors.primary,
            percentage: 0.45 // 45%
        )

        // Then
        XCTAssertEqual(segment.formattedPercentage, "45.0%")
    }

    func test_chartSegment_uniqueId() {
        // Given
        let segment1 = ChartSegment(
            label: "Federal",
            value: 10000,
            color: TNColors.primary,
            percentage: 0.5
        )
        let segment2 = ChartSegment(
            label: "Federal",
            value: 10000,
            color: TNColors.primary,
            percentage: 0.5
        )

        // Then - Each segment should have a unique ID
        XCTAssertNotEqual(segment1.id, segment2.id)
    }
}
