//
//  AssignmentViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for AssignmentViewModel
//

import XCTest
import SwiftData
@testable import TravelNurse

@MainActor
final class AssignmentViewModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: AssignmentService!
    var viewModel: AssignmentViewModel!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Assignment.self, Address.self, PayBreakdown.self, UserProfile.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        service = AssignmentService(modelContext: modelContext)
        viewModel = AssignmentViewModel(service: service)
    }

    override func tearDown() async throws {
        viewModel = nil
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestAssignment(
        facilityName: String = "Test Hospital",
        agencyName: String = "Test Agency",
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .day, value: 90, to: Date())!,
        status: AssignmentStatus = .active
    ) -> Assignment {
        Assignment(
            facilityName: facilityName,
            agencyName: agencyName,
            startDate: startDate,
            endDate: endDate,
            status: status
        )
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.assignments.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.selectedAssignment)
        XCTAssertEqual(viewModel.filterStatus, .all)
    }

    // MARK: - Load Assignments Tests

    func testLoadAssignments_emptyDatabase_returnsEmptyList() {
        viewModel.loadAssignments()

        XCTAssertTrue(viewModel.assignments.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadAssignments_withData_returnsAssignments() {
        // Arrange
        let assignment1 = createTestAssignment(facilityName: "Hospital A")
        let assignment2 = createTestAssignment(facilityName: "Hospital B")
        service.create(assignment1)
        service.create(assignment2)

        // Act
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.assignments.count, 2)
    }

    func testLoadAssignments_sortedByStartDateDescending() {
        // Arrange
        let oldDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        let recentDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!

        let oldAssignment = createTestAssignment(
            facilityName: "Old Hospital",
            startDate: oldDate,
            endDate: Calendar.current.date(byAdding: .day, value: 90, to: oldDate)!
        )
        let recentAssignment = createTestAssignment(
            facilityName: "Recent Hospital",
            startDate: recentDate,
            endDate: Calendar.current.date(byAdding: .day, value: 90, to: recentDate)!
        )

        service.create(oldAssignment)
        service.create(recentAssignment)

        // Act
        viewModel.loadAssignments()

        // Assert - most recent should be first
        XCTAssertEqual(viewModel.assignments.first?.facilityName, "Recent Hospital")
    }

    // MARK: - Filter Tests

    func testFilterByStatus_active_returnsOnlyActive() {
        // Arrange
        let activeAssignment = createTestAssignment(facilityName: "Active Hospital", status: .active)
        let completedAssignment = createTestAssignment(facilityName: "Completed Hospital", status: .completed)
        service.create(activeAssignment)
        service.create(completedAssignment)

        // Act
        viewModel.filterStatus = .active
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.filteredAssignments.count, 1)
        XCTAssertEqual(viewModel.filteredAssignments.first?.facilityName, "Active Hospital")
    }

    func testFilterByStatus_all_returnsAllAssignments() {
        // Arrange
        let activeAssignment = createTestAssignment(status: .active)
        let completedAssignment = createTestAssignment(status: .completed)
        let upcomingAssignment = createTestAssignment(status: .upcoming)
        service.create(activeAssignment)
        service.create(completedAssignment)
        service.create(upcomingAssignment)

        // Act
        viewModel.filterStatus = .all
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.filteredAssignments.count, 3)
    }

    // MARK: - Grouped Assignments Tests

    func testAssignmentsGroupedByYear() {
        // Arrange
        let date2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        let date2023 = Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 1))!

        let assignment2024 = createTestAssignment(
            facilityName: "Hospital 2024",
            startDate: date2024,
            endDate: Calendar.current.date(byAdding: .day, value: 90, to: date2024)!
        )
        let assignment2023 = createTestAssignment(
            facilityName: "Hospital 2023",
            startDate: date2023,
            endDate: Calendar.current.date(byAdding: .day, value: 90, to: date2023)!
        )

        service.create(assignment2024)
        service.create(assignment2023)

        // Act
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.assignmentYears.count, 2)
        XCTAssertTrue(viewModel.assignmentYears.contains(2024))
        XCTAssertTrue(viewModel.assignmentYears.contains(2023))
    }

    func testAssignmentsForYear_returnsCorrectAssignments() {
        // Arrange
        let date2024 = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        let date2023 = Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 1))!

        let assignment2024a = createTestAssignment(
            facilityName: "Hospital A 2024",
            startDate: date2024,
            endDate: Calendar.current.date(byAdding: .day, value: 90, to: date2024)!
        )
        let assignment2024b = createTestAssignment(
            facilityName: "Hospital B 2024",
            startDate: Calendar.current.date(byAdding: .month, value: 1, to: date2024)!,
            endDate: Calendar.current.date(byAdding: .day, value: 120, to: date2024)!
        )
        let assignment2023 = createTestAssignment(
            facilityName: "Hospital 2023",
            startDate: date2023,
            endDate: Calendar.current.date(byAdding: .day, value: 90, to: date2023)!
        )

        service.create(assignment2024a)
        service.create(assignment2024b)
        service.create(assignment2023)

        // Act
        viewModel.loadAssignments()
        let assignments2024 = viewModel.assignments(forYear: 2024)

        // Assert
        XCTAssertEqual(assignments2024.count, 2)
    }

    // MARK: - CRUD Tests

    func testAddAssignment_addsToList() {
        // Arrange
        let newAssignment = createTestAssignment(facilityName: "New Hospital")

        // Act
        viewModel.addAssignment(newAssignment)
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.assignments.count, 1)
        XCTAssertEqual(viewModel.assignments.first?.facilityName, "New Hospital")
    }

    func testUpdateAssignment_updatesData() {
        // Arrange
        let assignment = createTestAssignment(facilityName: "Original Name")
        service.create(assignment)
        viewModel.loadAssignments()

        // Act
        assignment.facilityName = "Updated Name"
        viewModel.updateAssignment(assignment)
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.assignments.first?.facilityName, "Updated Name")
    }

    func testDeleteAssignment_removesFromList() {
        // Arrange
        let assignment = createTestAssignment(facilityName: "To Delete")
        service.create(assignment)
        viewModel.loadAssignments()
        XCTAssertEqual(viewModel.assignments.count, 1)

        // Act
        viewModel.deleteAssignment(assignment)
        viewModel.loadAssignments()

        // Assert
        XCTAssertTrue(viewModel.assignments.isEmpty)
    }

    // MARK: - Selection Tests

    func testSelectAssignment_setsSelectedAssignment() {
        // Arrange
        let assignment = createTestAssignment(facilityName: "Selected Hospital")
        service.create(assignment)
        viewModel.loadAssignments()

        // Act
        viewModel.selectAssignment(assignment)

        // Assert
        XCTAssertEqual(viewModel.selectedAssignment?.id, assignment.id)
    }

    func testClearSelection_clearsSelectedAssignment() {
        // Arrange
        let assignment = createTestAssignment()
        service.create(assignment)
        viewModel.loadAssignments()
        viewModel.selectAssignment(assignment)

        // Act
        viewModel.clearSelection()

        // Assert
        XCTAssertNil(viewModel.selectedAssignment)
    }

    // MARK: - Current Assignment Tests

    func testCurrentAssignment_returnsActiveAssignment() {
        // Arrange
        let activeAssignment = createTestAssignment(facilityName: "Active", status: .active)
        let upcomingAssignment = createTestAssignment(facilityName: "Upcoming", status: .upcoming)
        service.create(activeAssignment)
        service.create(upcomingAssignment)

        // Act
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.currentAssignment?.facilityName, "Active")
    }

    func testCurrentAssignment_noActive_returnsNil() {
        // Arrange
        let completedAssignment = createTestAssignment(status: .completed)
        service.create(completedAssignment)

        // Act
        viewModel.loadAssignments()

        // Assert
        XCTAssertNil(viewModel.currentAssignment)
    }

    // MARK: - Statistics Tests

    func testTotalAssignments_returnsCorrectCount() {
        // Arrange
        service.create(createTestAssignment())
        service.create(createTestAssignment())
        service.create(createTestAssignment())

        // Act
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.totalAssignments, 3)
    }

    func testActiveAssignmentsCount_returnsCorrectCount() {
        // Arrange
        service.create(createTestAssignment(status: .active))
        service.create(createTestAssignment(status: .active))
        service.create(createTestAssignment(status: .completed))

        // Act
        viewModel.loadAssignments()

        // Assert
        XCTAssertEqual(viewModel.activeAssignmentsCount, 2)
    }
}

// MARK: - Filter Status Extension

extension AssignmentViewModelTests {
    /// Helper enum that matches ViewModel filter options
    enum FilterOption: String, CaseIterable {
        case all
        case active
        case upcoming
        case completed
        case cancelled
    }
}
