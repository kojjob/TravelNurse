//
//  DashboardViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for DashboardViewModel
//

import XCTest
@testable import TravelNurse

// MARK: - Test Cases

@MainActor
final class DashboardViewModelTests: XCTestCase {

    var sut: DashboardViewModel!

    override func setUp() {
        super.setUp()
        sut = DashboardViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_setsDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testInit_setsDefaultDashboardData() {
        XCTAssertNil(sut.currentAssignment)
        XCTAssertEqual(sut.complianceScore, 0)
        XCTAssertEqual(sut.complianceLevel, .unknown)
        XCTAssertNil(sut.daysUntilVisit)
        XCTAssertEqual(sut.totalMileage, 0)
        XCTAssertEqual(sut.totalMileageDeduction, 0)
        XCTAssertTrue(sut.recentExpenses.isEmpty)
        XCTAssertEqual(sut.totalYTDExpenses, 0)
        XCTAssertEqual(sut.totalYTDEarnings, 0)
        XCTAssertNil(sut.assignmentDaysRemaining)
    }

    // MARK: - Computed Properties Tests

    func testHasActiveAssignment_whenNoAssignment_returnsFalse() {
        XCTAssertFalse(sut.hasActiveAssignment)
    }

    func testAssignmentProgress_whenNoAssignment_returnsZero() {
        XCTAssertEqual(sut.assignmentProgress, 0)
    }

    func testComplianceStatusColor_returnsColorForLevel() {
        // Default level is .unknown
        XCTAssertNotNil(sut.complianceStatusColor)
    }

    // MARK: - Formatted Values Tests

    func testFormattedMileageDeduction_returnsCurrencyFormat() {
        XCTAssertTrue(sut.formattedMileageDeduction.contains("$"))
        XCTAssertTrue(sut.formattedMileageDeduction.contains("0"))
    }

    func testFormattedYTDExpenses_returnsCurrencyFormat() {
        XCTAssertTrue(sut.formattedYTDExpenses.contains("$"))
        XCTAssertTrue(sut.formattedYTDExpenses.contains("0"))
    }

    func testFormattedYTDEarnings_returnsCurrencyFormat() {
        XCTAssertTrue(sut.formattedYTDEarnings.contains("$"))
        XCTAssertTrue(sut.formattedYTDEarnings.contains("0"))
    }

    // MARK: - Data Loading Tests

    func testLoadData_setsIsLoading() {
        // loadData sets isLoading to true, then false when complete
        sut.loadData()

        // After completion, isLoading should be false
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadData_withoutServices_handlesGracefully() {
        // When services can't be configured, should set error message
        sut.loadData()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func testRefresh_callsLoadData() {
        // When
        sut.refresh()

        // Then - should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Error State Tests

    func testErrorMessage_canBeSet() {
        // Given
        XCTAssertNil(sut.errorMessage)

        // When
        sut.errorMessage = "Test error"

        // Then
        XCTAssertEqual(sut.errorMessage, "Test error")
    }

    func testErrorMessage_canBeCleared() {
        // Given
        sut.errorMessage = "Test error"

        // When
        sut.errorMessage = nil

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Loading State Tests

    func testIsLoading_canBeToggled() {
        // Given
        XCTAssertFalse(sut.isLoading)

        // When
        sut.isLoading = true

        // Then
        XCTAssertTrue(sut.isLoading)
    }
}

// NOTE: ComplianceLevelTests are in ComplianceLevelTests.swift

// MARK: - Assignment Model Tests

@MainActor
final class AssignmentModelTests: XCTestCase {

    func testInit_setsProperties() {
        // Given
        let facilityName = "City Hospital"
        let agencyName = "TravelNurse Agency"
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate)!

        // When
        let assignment = Assignment(
            facilityName: facilityName,
            agencyName: agencyName,
            startDate: startDate,
            endDate: endDate
        )

        // Then
        XCTAssertEqual(assignment.facilityName, facilityName)
        XCTAssertEqual(assignment.agencyName, agencyName)
        XCTAssertEqual(assignment.startDate, startDate)
        XCTAssertEqual(assignment.endDate, endDate)
        XCTAssertEqual(assignment.weeklyHours, 36) // default value
        XCTAssertEqual(assignment.shiftType, "Day") // default value
    }

    func testInit_acceptsCustomValues() {
        // Given
        let assignment = Assignment(
            facilityName: "Test Hospital",
            agencyName: "Test Agency",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90), // 90 days
            weeklyHours: 48,
            shiftType: "Night",
            unitName: "ICU",
            status: .active
        )

        // Then
        XCTAssertEqual(assignment.weeklyHours, 48)
        XCTAssertEqual(assignment.shiftType, "Night")
        XCTAssertEqual(assignment.unitName, "ICU")
        XCTAssertEqual(assignment.status, .active)
    }

    func testDurationWeeks_calculatesCorrectly() {
        // Given
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 13, to: startDate)!

        let assignment = Assignment(
            facilityName: "Test Hospital",
            agencyName: "Test Agency",
            startDate: startDate,
            endDate: endDate
        )

        // Then
        // Should be approximately 13 weeks
        XCTAssertGreaterThanOrEqual(assignment.durationWeeks, 12)
        XCTAssertLessThanOrEqual(assignment.durationWeeks, 14)
    }

    func testDurationDays_calculatesCorrectly() {
        // Given
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 90, to: startDate)!

        let assignment = Assignment(
            facilityName: "Test Hospital",
            agencyName: "Test Agency",
            startDate: startDate,
            endDate: endDate
        )

        // Then
        XCTAssertEqual(assignment.durationDays, 90)
    }

    func testProgressPercentage_whenActive_calculatesCorrectly() {
        // Given - assignment started 7 days ago, ends in 7 days
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        let assignment = Assignment(
            facilityName: "Active Hospital",
            agencyName: "Active Agency",
            startDate: startDate,
            endDate: endDate,
            status: .active
        )

        // Then - should be approximately 50% complete
        XCTAssertGreaterThan(assignment.progressPercentage, 40)
        XCTAssertLessThan(assignment.progressPercentage, 60)
    }

    func testStatus_defaultsToUpcoming() {
        // Given
        let assignment = Assignment(
            facilityName: "Future Hospital",
            agencyName: "Future Agency",
            startDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            endDate: Calendar.current.date(byAdding: .month, value: 4, to: Date())!
        )

        // Then
        XCTAssertEqual(assignment.status, .upcoming)
    }

    func testDateRangeFormatted_returnsNonEmptyString() {
        // Given
        let assignment = Assignment(
            facilityName: "Test Hospital",
            agencyName: "Test Agency",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90)
        )

        // Then
        XCTAssertFalse(assignment.dateRangeFormatted.isEmpty)
        XCTAssertTrue(assignment.dateRangeFormatted.contains("-"))
    }
}

// NOTE: USStateTests are in TravelNurseTests/Models/USStateTests.swift
