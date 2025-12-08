//
//  NotificationServiceTests.swift
//  TravelNurseTests
//
//  Tests for NotificationService - TDD approach
//

import XCTest
import UserNotifications
@testable import TravelNurse

final class NotificationServiceTests: XCTestCase {

    var sut: NotificationService!

    override func setUp() {
        super.setUp()
        sut = NotificationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Notification Type Tests

    func test_notificationType_30DayReminder_hasCorrectIdentifier() {
        XCTAssertEqual(NotificationType.thirtyDayReturnReminder.identifier, "thirty_day_return_reminder")
    }

    func test_notificationType_oneYearWarning_hasCorrectIdentifier() {
        XCTAssertEqual(NotificationType.oneYearRuleWarning.identifier, "one_year_rule_warning")
    }

    func test_notificationType_taxDeadline_hasCorrectIdentifier() {
        XCTAssertEqual(NotificationType.taxDeadlineReminder.identifier, "tax_deadline_reminder")
    }

    func test_notificationType_expenseReminder_hasCorrectIdentifier() {
        XCTAssertEqual(NotificationType.expenseReminder.identifier, "expense_reminder")
    }

    func test_notificationType_assignmentEnding_hasCorrectIdentifier() {
        XCTAssertEqual(NotificationType.assignmentEnding.identifier, "assignment_ending")
    }

    // MARK: - Content Creation Tests

    func test_createContent_thirtyDayReminder_hasCorrectTitle() {
        let content = sut.createNotificationContent(for: .thirtyDayReturnReminder)

        XCTAssertEqual(content.title, "Tax Home Reminder")
        XCTAssertTrue(content.body.contains("visit your tax home"))
    }

    func test_createContent_oneYearWarning_includesDaysInBody() {
        let content = sut.createNotificationContent(for: .oneYearRuleWarning, context: ["days": "300"])

        XCTAssertEqual(content.title, "One-Year Rule Alert")
        XCTAssertTrue(content.body.contains("300"))
    }

    func test_createContent_taxDeadline_includesQuarterInfo() {
        let content = sut.createNotificationContent(for: .taxDeadlineReminder, context: ["quarter": "Q1", "date": "April 15"])

        XCTAssertEqual(content.title, "Tax Deadline Reminder")
        XCTAssertTrue(content.body.contains("Q1"))
    }

    func test_createContent_expenseReminder_hasCorrectMessage() {
        let content = sut.createNotificationContent(for: .expenseReminder)

        XCTAssertEqual(content.title, "Expense Tracking Reminder")
        XCTAssertTrue(content.body.contains("expense"))
    }

    func test_createContent_assignmentEnding_includesDays() {
        let content = sut.createNotificationContent(for: .assignmentEnding, context: ["days": "14", "facility": "Memorial Hospital"])

        XCTAssertEqual(content.title, "Assignment Ending Soon")
        XCTAssertTrue(content.body.contains("14"))
    }

    // MARK: - Trigger Creation Tests

    func test_createDailyTrigger_returnsCorrectTrigger() {
        let trigger = sut.createDailyTrigger(hour: 9, minute: 0)

        XCTAssertNotNil(trigger)
        guard let calendarTrigger = trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Expected calendar trigger")
            return
        }

        XCTAssertEqual(calendarTrigger.dateComponents.hour, 9)
        XCTAssertEqual(calendarTrigger.dateComponents.minute, 0)
        XCTAssertTrue(calendarTrigger.repeats)
    }

    func test_createWeeklyTrigger_returnsCorrectTrigger() {
        let trigger = sut.createWeeklyTrigger(weekday: 2, hour: 10, minute: 0) // Monday at 10 AM

        XCTAssertNotNil(trigger)
        guard let calendarTrigger = trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Expected calendar trigger")
            return
        }

        XCTAssertEqual(calendarTrigger.dateComponents.weekday, 2)
        XCTAssertEqual(calendarTrigger.dateComponents.hour, 10)
        XCTAssertTrue(calendarTrigger.repeats)
    }

    func test_createDateTrigger_returnsTriggerForFutureDate() {
        let futureDate = Date().addingTimeInterval(86400) // Tomorrow
        let trigger = sut.createDateTrigger(for: futureDate)

        XCTAssertNotNil(trigger)
        guard let calendarTrigger = trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Expected calendar trigger")
            return
        }

        XCTAssertFalse(calendarTrigger.repeats)
    }

    // MARK: - Tax Deadline Tests

    func test_quarterlyTaxDeadlines_returnsCorrectDates() {
        let deadlines = NotificationService.quarterlyTaxDeadlines(for: 2025)

        XCTAssertEqual(deadlines.count, 4)

        let calendar = Calendar.current

        // Q1: April 15
        let q1 = deadlines[0]
        XCTAssertEqual(calendar.component(.month, from: q1.date), 4)
        XCTAssertEqual(calendar.component(.day, from: q1.date), 15)
        XCTAssertEqual(q1.quarter, "Q1")

        // Q2: June 15
        let q2 = deadlines[1]
        XCTAssertEqual(calendar.component(.month, from: q2.date), 6)
        XCTAssertEqual(calendar.component(.day, from: q2.date), 15)
        XCTAssertEqual(q2.quarter, "Q2")

        // Q3: September 15
        let q3 = deadlines[2]
        XCTAssertEqual(calendar.component(.month, from: q3.date), 9)
        XCTAssertEqual(calendar.component(.day, from: q3.date), 15)
        XCTAssertEqual(q3.quarter, "Q3")

        // Q4: January 15 (next year)
        let q4 = deadlines[3]
        XCTAssertEqual(calendar.component(.month, from: q4.date), 1)
        XCTAssertEqual(calendar.component(.day, from: q4.date), 15)
        XCTAssertEqual(q4.quarter, "Q4")
    }

    // MARK: - One Year Rule Warning Tests

    func test_oneYearWarningDays_returnsCorrectThresholds() {
        let thresholds = NotificationService.oneYearWarningDays

        XCTAssertEqual(thresholds.count, 3)
        XCTAssertTrue(thresholds.contains(300))
        XCTAssertTrue(thresholds.contains(330))
        XCTAssertTrue(thresholds.contains(350))
    }

    // MARK: - Notification Request Tests

    func test_createRequest_hasCorrectIdentifier() {
        let content = sut.createNotificationContent(for: .expenseReminder)
        let trigger = sut.createWeeklyTrigger(weekday: 2, hour: 9, minute: 0)

        let request = sut.createNotificationRequest(
            type: .expenseReminder,
            content: content,
            trigger: trigger
        )

        XCTAssertTrue(request.identifier.contains(NotificationType.expenseReminder.identifier))
    }

    // MARK: - Days Until Tax Home Visit Tests

    func test_daysUntil30DayLimit_calculatesCorrectly() {
        // Given
        let lastVisit = Calendar.current.date(byAdding: .day, value: -25, to: Date())!

        // When
        let daysRemaining = sut.daysUntil30DayLimit(lastVisit: lastVisit)

        // Then
        XCTAssertEqual(daysRemaining, 5)
    }

    func test_daysUntil30DayLimit_returnsZeroWhenPastLimit() {
        // Given
        let lastVisit = Calendar.current.date(byAdding: .day, value: -35, to: Date())!

        // When
        let daysRemaining = sut.daysUntil30DayLimit(lastVisit: lastVisit)

        // Then
        XCTAssertEqual(daysRemaining, 0)
    }

    // MARK: - Badge Number Tests

    func test_calculateBadgeCount_returnsCorrectCount() {
        let pendingNotifications = [
            NotificationType.thirtyDayReturnReminder,
            NotificationType.oneYearRuleWarning,
            NotificationType.taxDeadlineReminder
        ]

        let badgeCount = sut.calculateBadgeCount(for: pendingNotifications)

        XCTAssertEqual(badgeCount, 3)
    }

    func test_calculateBadgeCount_returnsZeroForEmptyArray() {
        let badgeCount = sut.calculateBadgeCount(for: [])

        XCTAssertEqual(badgeCount, 0)
    }
}
