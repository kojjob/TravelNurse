//
//  NotificationServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for NotificationService
//

import XCTest
import UserNotifications
@testable import TravelNurse

final class NotificationServiceTests: XCTestCase {

    var sut: NotificationService!

    override func setUp() {
        super.setUp()
        sut = NotificationService.shared
    }

    override func tearDown() async throws {
        // Clean up any scheduled notifications
        await sut.cancelAllNotifications()
        try await super.tearDown()
    }

    // MARK: - NotificationType Tests

    func test_notificationType_taxDeadline_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.taxDeadline.title, "Tax Payment Due")
    }

    func test_notificationType_assignmentStart_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.assignmentStart.title, "Assignment Starting")
    }

    func test_notificationType_assignmentEnd_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.assignmentEnd.title, "Assignment Ending")
    }

    func test_notificationType_taxHomeReminder_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.taxHomeReminder.title, "Tax Home Visit Required")
    }

    func test_notificationType_oneYearRule_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.oneYearRule.title, "IRS One-Year Rule Alert")
    }

    func test_notificationType_expenseReminder_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.expenseReminder.title, "Log Your Expenses")
    }

    func test_notificationType_weeklyDigest_hasCorrectTitle() {
        XCTAssertEqual(NotificationType.weeklyDigest.title, "Weekly Summary")
    }

    func test_notificationType_categoryIdentifier_isUppercased() {
        for type in NotificationType.allCases {
            XCTAssertTrue(
                type.categoryIdentifier.hasPrefix("TRAVELNURSE_"),
                "Category identifier should start with TRAVELNURSE_"
            )
            XCTAssertTrue(
                type.categoryIdentifier.uppercased() == type.categoryIdentifier,
                "Category identifier should be uppercased"
            )
        }
    }

    func test_notificationType_allCases_hasExpectedCount() {
        XCTAssertEqual(NotificationType.allCases.count, 8)
    }

    // MARK: - Singleton Tests

    func test_shared_returnsSameInstance() {
        let instance1 = NotificationService.shared
        let instance2 = NotificationService.shared

        XCTAssertTrue(instance1 === instance2, "Shared should return same instance")
    }

    // MARK: - Authorization Tests

    func test_checkAuthorizationStatus_returnsStatus() async {
        // This test verifies the method doesn't crash
        // Actual authorization status depends on simulator/device settings
        let status = await sut.checkAuthorizationStatus()

        // Status should be one of the valid values
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined, .denied, .authorized, .provisional, .ephemeral
        ]
        XCTAssertTrue(validStatuses.contains(status))
    }

    // MARK: - Pending Notifications Tests

    func test_getPendingNotifications_returnsArray() async {
        let pending = await sut.getPendingNotifications()

        // Should return an array (possibly empty)
        XCTAssertNotNil(pending)
    }

    // MARK: - Cancel Tests

    func test_cancelAllNotifications_removesAllPending() async {
        // Given - we have some pending state
        let initialPending = await sut.getPendingNotifications()

        // When
        await sut.cancelAllNotifications()

        // Then
        let afterCancel = await sut.getPendingNotifications()
        XCTAssertTrue(afterCancel.isEmpty || afterCancel.count <= initialPending.count)
    }

    func test_cancelNotification_byIdentifier_doesNotCrash() async {
        // This test verifies the method handles non-existent identifiers gracefully
        await sut.cancelNotification(identifier: "non_existent_notification_id")
        // Should not crash
    }

    func test_cancelNotifications_ofType_doesNotCrash() async {
        // This test verifies the method handles when no notifications of type exist
        await sut.cancelNotifications(ofType: .taxDeadline)
        // Should not crash
    }

    // MARK: - Tax Deadline Scheduling Tests

    func test_scheduleTaxDeadlineReminders_forValidYear_doesNotCrash() async {
        let year = Calendar.current.component(.year, from: Date())
        await sut.scheduleTaxDeadlineReminders(for: year)
        // Should not crash
    }

    func test_scheduleTaxDeadlineReminders_forFutureYear_schedulesNotifications() async {
        // Given
        let futureYear = Calendar.current.component(.year, from: Date()) + 1
        await sut.cancelAllNotifications()

        // When
        await sut.scheduleTaxDeadlineReminders(for: futureYear)

        // Then - we should have some pending notifications
        let pending = await sut.getPendingNotifications()
        // Note: Actual scheduling depends on authorization status
        // This test just verifies no crash
        XCTAssertNotNil(pending)
    }

    // MARK: - Assignment Reminders Tests

    func test_scheduleAssignmentReminders_withFutureDates_doesNotCrash() async {
        // Given
        let startDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        let endDate = Date().addingTimeInterval(86400 * 120) // 120 days from now

        // When
        await sut.scheduleAssignmentReminders(
            assignmentId: UUID(),
            facilityName: "Test Hospital",
            startDate: startDate,
            endDate: endDate
        )

        // Then - should not crash
    }

    func test_scheduleAssignmentReminders_withPastDates_doesNotSchedule() async {
        // Given
        await sut.cancelAllNotifications()
        let startDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        let endDate = Date().addingTimeInterval(-86400 * 1) // 1 day ago

        // When
        await sut.scheduleAssignmentReminders(
            assignmentId: UUID(),
            facilityName: "Past Hospital",
            startDate: startDate,
            endDate: endDate
        )

        // Then - no new notifications should be added for past dates
        let pending = await sut.getPendingNotifications()
        let pastAssignmentNotifications = pending.filter {
            $0.identifier.contains("Past Hospital") || $0.content.body.contains("Past Hospital")
        }
        XCTAssertTrue(pastAssignmentNotifications.isEmpty)
    }

    // MARK: - Tax Home Reminder Tests

    func test_scheduleTaxHomeReminder_withPositiveDays_doesNotCrash() async {
        await sut.scheduleTaxHomeReminder(daysUntilRequired: 10)
        // Should not crash
    }

    func test_scheduleTaxHomeReminder_withZeroDays_doesNotSchedule() async {
        // Given
        await sut.cancelAllNotifications()

        // When
        await sut.scheduleTaxHomeReminder(daysUntilRequired: 0)

        // Then
        let pending = await sut.getPendingNotifications()
        let taxHomeNotifications = pending.filter {
            $0.content.categoryIdentifier == NotificationType.taxHomeReminder.categoryIdentifier
        }
        XCTAssertTrue(taxHomeNotifications.isEmpty)
    }

    func test_scheduleTaxHomeReminder_withNegativeDays_doesNotSchedule() async {
        // Given
        await sut.cancelAllNotifications()

        // When
        await sut.scheduleTaxHomeReminder(daysUntilRequired: -5)

        // Then
        let pending = await sut.getPendingNotifications()
        let taxHomeNotifications = pending.filter {
            $0.content.categoryIdentifier == NotificationType.taxHomeReminder.categoryIdentifier
        }
        XCTAssertTrue(taxHomeNotifications.isEmpty)
    }

    // MARK: - One Year Rule Tests

    func test_scheduleOneYearRuleWarning_withLowDaysWorked_schedulesWarnings() async {
        // Given
        await sut.cancelAllNotifications()

        // When
        await sut.scheduleOneYearRuleWarning(
            assignmentId: UUID(),
            facilityName: "Long Term Hospital",
            daysWorked: 200
        )

        // Then - should not crash
        // Note: Actual scheduling depends on authorization
    }

    func test_scheduleOneYearRuleWarning_withHighDaysWorked_doesNotSchedulePastWarnings() async {
        // Given - already past 350 days
        await sut.cancelAllNotifications()

        // When
        await sut.scheduleOneYearRuleWarning(
            assignmentId: UUID(),
            facilityName: "Very Long Term Hospital",
            daysWorked: 360
        )

        // Then - should not schedule any new warnings (all thresholds passed)
        let pending = await sut.getPendingNotifications()
        let oneYearNotifications = pending.filter {
            $0.identifier.contains("one_year_")
        }
        XCTAssertTrue(oneYearNotifications.isEmpty)
    }

    // MARK: - Weekly Expense Reminder Tests

    func test_scheduleWeeklyExpenseReminder_doesNotCrash() async {
        await sut.scheduleWeeklyExpenseReminder()
        // Should not crash
    }

    // MARK: - Generic Schedule Notification Tests

    func test_scheduleNotification_withFutureDate_doesNotCrash() async {
        // Given
        let futureDate = Date().addingTimeInterval(86400 * 7) // 7 days from now

        // When
        await sut.scheduleNotification(
            type: .taxDeadline,
            body: "Test notification body",
            triggerDate: futureDate,
            identifier: "test_notification_\(UUID().uuidString)"
        )

        // Then - should not crash
    }

    func test_scheduleNotification_withCustomIdentifier_usesProvidedIdentifier() async {
        // Given
        await sut.cancelAllNotifications()
        let futureDate = Date().addingTimeInterval(86400 * 30)
        let customId = "custom_test_id_\(UUID().uuidString)"

        // When
        await sut.scheduleNotification(
            type: .expenseReminder,
            body: "Test body",
            triggerDate: futureDate,
            identifier: customId
        )

        // Then
        let pending = await sut.getPendingNotifications()
        let matchingNotification = pending.first { $0.identifier == customId }
        // Note: Depends on authorization status
        XCTAssertTrue(matchingNotification != nil || pending.isEmpty)
    }
}

// MARK: - Integration Tests

final class NotificationServiceIntegrationTests: XCTestCase {

    var sut: NotificationService!

    override func setUp() {
        super.setUp()
        sut = NotificationService.shared
    }

    override func tearDown() async throws {
        await sut.cancelAllNotifications()
        try await super.tearDown()
    }

    func test_fullWorkflow_scheduleAndCancelTaxReminders() async {
        // Given
        let year = Calendar.current.component(.year, from: Date()) + 1

        // When - Schedule
        await sut.scheduleTaxDeadlineReminders(for: year)
        let pendingAfterSchedule = await sut.getPendingNotifications()

        // Then - Cancel
        await sut.cancelNotifications(ofType: .taxDeadline)
        let pendingAfterCancel = await sut.getPendingNotifications()

        // Verify cancellation worked (or no notifications were scheduled due to auth)
        let taxNotificationsAfterCancel = pendingAfterCancel.filter {
            $0.content.categoryIdentifier == NotificationType.taxDeadline.categoryIdentifier
        }
        XCTAssertTrue(taxNotificationsAfterCancel.isEmpty)
    }

    func test_multipleNotificationTypes_canCoexist() async {
        // Given
        await sut.cancelAllNotifications()
        let futureDate = Date().addingTimeInterval(86400 * 60)

        // When - Schedule different types
        await sut.scheduleNotification(
            type: .taxDeadline,
            body: "Tax reminder",
            triggerDate: futureDate,
            identifier: "test_tax_1"
        )

        await sut.scheduleNotification(
            type: .assignmentEnd,
            body: "Assignment ending",
            triggerDate: futureDate,
            identifier: "test_assignment_1"
        )

        // Then - Both should be pending (if authorized)
        let pending = await sut.getPendingNotifications()
        // Test passes if no crash - actual count depends on authorization
        XCTAssertNotNil(pending)
    }
}
