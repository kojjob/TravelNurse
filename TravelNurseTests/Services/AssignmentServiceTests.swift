//
//  AssignmentServiceTests.swift
//  TravelNurseTests
//
//  Tests for AssignmentService - TDD approach
//

import XCTest
import SwiftData
@testable import TravelNurse

final class AssignmentServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var sut: AssignmentService!

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
            sut = AssignmentService(modelContext: modelContext)
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

    // MARK: - Create Tests

    @MainActor
    func test_createAssignment_insertsIntoContext() throws {
        // Given
        let assignment = Assignment(
            facilityName: "Memorial Hospital",
            agencyName: "TravelNurse Agency",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 90) // 90 days
        )

        // When
        sut.create(assignment)

        // Then
        let descriptor = FetchDescriptor<Assignment>()
        let assignments = try modelContext.fetch(descriptor)
        XCTAssertEqual(assignments.count, 1)
        XCTAssertEqual(assignments.first?.facilityName, "Memorial Hospital")
    }

    @MainActor
    func test_createAssignment_setsUpdatedAt() throws {
        // Given
        let beforeCreation = Date()
        let assignment = Assignment(
            facilityName: "Test Hospital",
            agencyName: "Test Agency",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 30)
        )

        // When
        sut.create(assignment)

        // Then
        XCTAssertGreaterThanOrEqual(assignment.updatedAt, beforeCreation)
    }

    // MARK: - Fetch Tests

    @MainActor
    func test_fetchAll_returnsAllAssignments() throws {
        // Given
        createTestAssignment(facilityName: "Hospital A")
        createTestAssignment(facilityName: "Hospital B")
        createTestAssignment(facilityName: "Hospital C")

        // When
        let assignments = sut.fetchAllOrEmpty()

        // Then
        XCTAssertEqual(assignments.count, 3)
    }

    @MainActor
    func test_fetchAll_returnsEmptyArrayWhenNoAssignments() {
        // When
        let assignments = sut.fetchAllOrEmpty()

        // Then
        XCTAssertTrue(assignments.isEmpty)
    }

    @MainActor
    func test_fetchById_returnsCorrectAssignment() throws {
        // Given
        let assignment = createTestAssignment(facilityName: "Target Hospital")
        let targetId = assignment.id
        createTestAssignment(facilityName: "Other Hospital")

        // When
        let result = try sut.fetch(byId: targetId).get()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.facilityName, "Target Hospital")
    }

    @MainActor
    func test_fetchById_returnsNilForInvalidId() throws {
        // Given
        createTestAssignment(facilityName: "Some Hospital")

        // When
        let result = try sut.fetch(byId: UUID()).get()

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Filter Tests

    @MainActor
    func test_fetchByStatus_returnsMatchingAssignments() throws {
        // Given
        let active = createTestAssignment(facilityName: "Active Hospital", status: .active)
        createTestAssignment(facilityName: "Completed Hospital", status: .completed)
        createTestAssignment(facilityName: "Upcoming Hospital", status: .upcoming)

        // When
        let activeAssignments = try sut.fetch(byStatus: .active).get()

        // Then
        XCTAssertEqual(activeAssignments.count, 1)
        XCTAssertEqual(activeAssignments.first?.id, active.id)
    }

    @MainActor
    func test_fetchCurrentAssignment_returnsActiveAssignment() throws {
        // Given
        createTestAssignment(facilityName: "Past Hospital", status: .completed)
        let current = createTestAssignment(facilityName: "Current Hospital", status: .active)
        createTestAssignment(facilityName: "Future Hospital", status: .upcoming)

        // When
        let result = sut.fetchCurrentAssignmentOrNil()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, current.id)
    }

    @MainActor
    func test_fetchByYear_returnsAssignmentsStartingInYear() throws {
        // Given
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())

        let thisYearDate = calendar.date(from: DateComponents(year: thisYear, month: 6, day: 1))!
        let lastYearDate = calendar.date(from: DateComponents(year: thisYear - 1, month: 6, day: 1))!

        createTestAssignment(facilityName: "This Year", startDate: thisYearDate)
        createTestAssignment(facilityName: "Last Year", startDate: lastYearDate)

        // When
        let thisYearAssignments = sut.fetchByYearOrEmpty(thisYear)

        // Then
        XCTAssertEqual(thisYearAssignments.count, 1)
        XCTAssertEqual(thisYearAssignments.first?.facilityName, "This Year")
    }

    // MARK: - Update Tests

    @MainActor
    func test_update_modifiesAssignment() throws {
        // Given
        let assignment = createTestAssignment(facilityName: "Original Name")

        // When
        assignment.facilityName = "Updated Name"
        sut.updateQuietly(assignment)

        // Then
        let fetched = try sut.fetch(byId: assignment.id).get()
        XCTAssertEqual(fetched?.facilityName, "Updated Name")
    }

    @MainActor
    func test_update_updatesTimestamp() throws {
        // Given
        let assignment = createTestAssignment(facilityName: "Test")
        let originalUpdatedAt = assignment.updatedAt

        // Wait a moment to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        // When
        assignment.facilityName = "Modified"
        sut.update(assignment)

        // Then
        XCTAssertGreaterThan(assignment.updatedAt, originalUpdatedAt)
    }

    // MARK: - Delete Tests

    @MainActor
    func test_delete_removesAssignment() throws {
        // Given
        let assignment = createTestAssignment(facilityName: "To Delete")
        let id = assignment.id
        XCTAssertEqual(sut.fetchAllOrEmpty().count, 1)

        // When
        sut.deleteQuietly(assignment)

        // Then
        XCTAssertEqual(sut.fetchAllOrEmpty().count, 0)
        let fetched = try sut.fetch(byId: id).get()
        XCTAssertNil(fetched)
    }

    // MARK: - Statistics Tests

    @MainActor
    func test_totalEarnings_calculatesCorrectSum() throws {
        // Given
        let assignment1 = createTestAssignment(facilityName: "Hospital 1")
        let pay1 = PayBreakdown(hourlyRate: 50, guaranteedHours: 36)
        assignment1.payBreakdown = pay1

        let assignment2 = createTestAssignment(facilityName: "Hospital 2")
        let pay2 = PayBreakdown(hourlyRate: 60, guaranteedHours: 36)
        assignment2.payBreakdown = pay2

        try modelContext.save()

        // When
        let total = sut.totalEarnings(forYear: Calendar.current.component(.year, from: Date()))

        // Then
        // Total should be sum of (weeklyGross * durationWeeks) for each assignment
        XCTAssertGreaterThan(total, 0)
    }

    @MainActor
    func test_assignmentCount_returnsCorrectCount() {
        // Given
        createTestAssignment(facilityName: "Hospital 1", status: .completed)
        createTestAssignment(facilityName: "Hospital 2", status: .completed)
        createTestAssignment(facilityName: "Hospital 3", status: .active)

        // When
        let completedCount = sut.assignmentCount(withStatus: .completed)
        let activeCount = sut.assignmentCount(withStatus: .active)

        // Then
        XCTAssertEqual(completedCount, 2)
        XCTAssertEqual(activeCount, 1)
    }

    // MARK: - Helper Methods

    @MainActor
    @discardableResult
    private func createTestAssignment(
        facilityName: String,
        status: AssignmentStatus = .active,
        startDate: Date? = nil
    ) -> Assignment {
        let start = startDate ?? Date()
        let assignment = Assignment(
            facilityName: facilityName,
            agencyName: "Test Agency",
            startDate: start,
            endDate: start.addingTimeInterval(86400 * 90), // 90 days
            status: status
        )
        modelContext.insert(assignment)
        try? modelContext.save()
        return assignment
    }
}
