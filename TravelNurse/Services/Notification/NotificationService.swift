//
//  NotificationService.swift
//  TravelNurse
//
//  Service for managing local push notifications for travel nurse compliance
//

import Foundation
import UserNotifications

// MARK: - Notification Types

/// Types of notifications the app can send to travel nurses
public enum NotificationType: String, CaseIterable {
    case thirtyDayReturnReminder
    case oneYearRuleWarning
    case taxDeadlineReminder
    case expenseReminder
    case assignmentEnding

    /// Unique identifier for this notification type
    public var identifier: String {
        switch self {
        case .thirtyDayReturnReminder:
            return "thirty_day_return_reminder"
        case .oneYearRuleWarning:
            return "one_year_rule_warning"
        case .taxDeadlineReminder:
            return "tax_deadline_reminder"
        case .expenseReminder:
            return "expense_reminder"
        case .assignmentEnding:
            return "assignment_ending"
        }
    }
}

// MARK: - Tax Deadline Model

/// Represents a quarterly tax deadline
public struct TaxDeadline {
    public let date: Date
    public let quarter: String

    public init(date: Date, quarter: String) {
        self.date = date
        self.quarter = quarter
    }
}

// MARK: - Notification Service Protocol

/// Protocol for notification service operations
public protocol NotificationServiceProtocol {
    func createNotificationContent(for type: NotificationType, context: [String: String]) -> UNMutableNotificationContent
    func createDailyTrigger(hour: Int, minute: Int) -> UNNotificationTrigger
    func createWeeklyTrigger(weekday: Int, hour: Int, minute: Int) -> UNNotificationTrigger
    func createDateTrigger(for date: Date) -> UNNotificationTrigger
    func createNotificationRequest(type: NotificationType, content: UNNotificationContent, trigger: UNNotificationTrigger?) -> UNNotificationRequest
    func daysUntil30DayLimit(lastVisit: Date) -> Int
    func calculateBadgeCount(for notifications: [NotificationType]) -> Int
}

// MARK: - Notification Service

/// Service for creating and scheduling local notifications for travel nurse compliance tracking
public final class NotificationService: NotificationServiceProtocol {

    // MARK: - Static Properties

    /// Warning thresholds in days for the one-year rule (365 days max at one location)
    public static let oneYearWarningDays: [Int] = [300, 330, 350]

    /// The maximum days allowed away from tax home before a return visit is required
    private static let taxHomeReturnDays: Int = 30

    // MARK: - Initialization

    public init() {}

    // MARK: - Static Methods

    /// Returns the quarterly estimated tax deadlines for a given year
    /// - Parameter year: The tax year
    /// - Returns: Array of TaxDeadline objects for Q1-Q4
    public static func quarterlyTaxDeadlines(for year: Int) -> [TaxDeadline] {
        let calendar = Calendar.current

        // Q1: Income Jan-Mar, due April 15
        let q1Components = DateComponents(year: year, month: 4, day: 15)
        let q1Date = calendar.date(from: q1Components)!

        // Q2: Income Apr-May, due June 15
        let q2Components = DateComponents(year: year, month: 6, day: 15)
        let q2Date = calendar.date(from: q2Components)!

        // Q3: Income Jun-Aug, due September 15
        let q3Components = DateComponents(year: year, month: 9, day: 15)
        let q3Date = calendar.date(from: q3Components)!

        // Q4: Income Sep-Dec, due January 15 of next year
        let q4Components = DateComponents(year: year + 1, month: 1, day: 15)
        let q4Date = calendar.date(from: q4Components)!

        return [
            TaxDeadline(date: q1Date, quarter: "Q1"),
            TaxDeadline(date: q2Date, quarter: "Q2"),
            TaxDeadline(date: q3Date, quarter: "Q3"),
            TaxDeadline(date: q4Date, quarter: "Q4")
        ]
    }

    // MARK: - Content Creation

    /// Creates notification content for a specific notification type
    /// - Parameters:
    ///   - type: The type of notification to create
    ///   - context: Optional context dictionary for dynamic content
    /// - Returns: Configured notification content
    public func createNotificationContent(
        for type: NotificationType,
        context: [String: String] = [:]
    ) -> UNMutableNotificationContent {
        ServiceLogger.log(
            "Creating notification content for type: \(type.identifier)",
            category: .notification,
            level: .debug
        )

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch type {
        case .thirtyDayReturnReminder:
            content.title = "Tax Home Reminder"
            content.body = "It's time to visit your tax home to maintain your travel nurse tax status."

        case .oneYearRuleWarning:
            content.title = "One-Year Rule Alert"
            let days = context["days"] ?? "unknown"
            content.body = "You've been at your current assignment for \(days) days. The IRS one-year rule limit is approaching."

        case .taxDeadlineReminder:
            content.title = "Tax Deadline Reminder"
            let quarter = context["quarter"] ?? ""
            let date = context["date"] ?? ""
            content.body = "\(quarter) estimated tax payment is due \(date). Don't forget to submit your payment."

        case .expenseReminder:
            content.title = "Expense Tracking Reminder"
            content.body = "Remember to log your work-related expense receipts to maximize your tax deductions."

        case .assignmentEnding:
            content.title = "Assignment Ending Soon"
            let days = context["days"] ?? "soon"
            let facility = context["facility"] ?? "your current facility"
            content.body = "Your assignment at \(facility) ends in \(days) days. Start planning your next steps."
        }

        return content
    }

    // MARK: - Trigger Creation

    /// Creates a daily repeating trigger at the specified time
    /// - Parameters:
    ///   - hour: Hour of day (0-23)
    ///   - minute: Minute of hour (0-59)
    /// - Returns: A calendar-based notification trigger
    public func createDailyTrigger(hour: Int, minute: Int) -> UNNotificationTrigger {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }

    /// Creates a weekly repeating trigger at the specified day and time
    /// - Parameters:
    ///   - weekday: Day of week (1 = Sunday, 2 = Monday, etc.)
    ///   - hour: Hour of day (0-23)
    ///   - minute: Minute of hour (0-59)
    /// - Returns: A calendar-based notification trigger
    public func createWeeklyTrigger(weekday: Int, hour: Int, minute: Int) -> UNNotificationTrigger {
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }

    /// Creates a one-time trigger for a specific date
    /// - Parameter date: The date when the notification should fire
    /// - Returns: A calendar-based notification trigger
    public func createDateTrigger(for date: Date) -> UNNotificationTrigger {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    // MARK: - Request Creation

    /// Creates a notification request with a unique identifier
    /// - Parameters:
    ///   - type: The notification type
    ///   - content: The notification content
    ///   - trigger: Optional trigger (nil = immediate delivery)
    /// - Returns: A configured notification request
    public func createNotificationRequest(
        type: NotificationType,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger?
    ) -> UNNotificationRequest {
        let identifier = "\(type.identifier)_\(UUID().uuidString)"

        ServiceLogger.log(
            "Created notification request: \(identifier)",
            category: .notification,
            level: .info
        )

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    // MARK: - Calculation Methods

    /// Calculates days remaining until the 30-day tax home return limit
    /// - Parameter lastVisit: The date of the last tax home visit
    /// - Returns: Days remaining (0 if already past limit)
    public func daysUntil30DayLimit(lastVisit: Date) -> Int {
        let calendar = Calendar.current
        let today = Date()

        guard let daysSinceVisit = calendar.dateComponents([.day], from: lastVisit, to: today).day else {
            return 0
        }

        let daysRemaining = Self.taxHomeReturnDays - daysSinceVisit
        return max(0, daysRemaining)
    }

    /// Calculates the badge count based on pending notifications
    /// - Parameter notifications: Array of pending notification types
    /// - Returns: The count to display on the app badge
    public func calculateBadgeCount(for notifications: [NotificationType]) -> Int {
        return notifications.count
    }
}
