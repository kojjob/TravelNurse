//
//  NotificationService.swift
//  TravelNurse
//
//  Service for managing local push notifications
//

import Foundation
import UserNotifications

/// Types of notifications the app can send
public enum NotificationType: String, CaseIterable {
    case taxDeadline = "tax_deadline"
    case assignmentStart = "assignment_start"
    case assignmentEnd = "assignment_end"
    case assignmentMilestone = "assignment_milestone"
    case taxHomeReminder = "tax_home_reminder"
    case expenseReminder = "expense_reminder"
    case weeklyDigest = "weekly_digest"
    case oneYearRule = "one_year_rule"
    case documentExpiry = "document_expiry"

    var title: String {
        switch self {
        case .taxDeadline: return "Tax Payment Due"
        case .assignmentStart: return "Assignment Starting"
        case .assignmentEnd: return "Assignment Ending"
        case .assignmentMilestone: return "Assignment Milestone"
        case .taxHomeReminder: return "Tax Home Visit Required"
        case .expenseReminder: return "Log Your Expenses"
        case .weeklyDigest: return "Weekly Summary"
        case .oneYearRule: return "IRS One-Year Rule Alert"
        case .documentExpiry: return "Document Expiring Soon"
        }
    }

    var categoryIdentifier: String {
        "TRAVELNURSE_\(rawValue.uppercased())"
    }
}

/// Protocol defining notification service operations
public protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
    func scheduleNotification(type: NotificationType, body: String, triggerDate: Date, identifier: String?) async
    func scheduleTaxDeadlineReminders(for year: Int) async
    func scheduleAssignmentReminders(assignmentId: UUID, facilityName: String, startDate: Date, endDate: Date) async
    func scheduleTaxHomeReminder(daysUntilRequired: Int) async
    func scheduleOneYearRuleWarning(assignmentId: UUID, facilityName: String, daysWorked: Int) async
    func scheduleWeeklyExpenseReminder() async
    func cancelNotification(identifier: String) async
    func cancelAllNotifications() async
    func cancelNotifications(ofType type: NotificationType) async
    func cancelAssignmentNotifications(assignmentId: UUID) async
    func getPendingNotifications() async -> [UNNotificationRequest]
}

/// Service for managing local push notifications
public final class NotificationService: NotificationServiceProtocol {

    // MARK: - Singleton

    public static let shared = NotificationService()

    // MARK: - Properties

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {}

    // MARK: - Authorization

    /// Request notification authorization from the user
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await notificationCenter.requestAuthorization(options: options)

            if granted {
                await registerNotificationCategories()
            }

            return granted
        } catch {
            ServiceLogger.log("Failed to request notification authorization", category: .notification, level: .error, error: error)
            return false
        }
    }

    /// Check current authorization status
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Notification Categories

    private func registerNotificationCategories() async {
        var categories: Set<UNNotificationCategory> = []

        // Tax deadline category with actions
        let taxDeadlineCategory = UNNotificationCategory(
            identifier: NotificationType.taxDeadline.categoryIdentifier,
            actions: [
                UNNotificationAction(identifier: "VIEW_TAXES", title: "View Taxes", options: .foreground),
                UNNotificationAction(identifier: "REMIND_LATER", title: "Remind Tomorrow", options: [])
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        categories.insert(taxDeadlineCategory)

        // Assignment category
        let assignmentCategory = UNNotificationCategory(
            identifier: NotificationType.assignmentStart.categoryIdentifier,
            actions: [
                UNNotificationAction(identifier: "VIEW_ASSIGNMENT", title: "View Assignment", options: .foreground)
            ],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(assignmentCategory)

        // Tax home reminder category
        let taxHomeCategory = UNNotificationCategory(
            identifier: NotificationType.taxHomeReminder.categoryIdentifier,
            actions: [
                UNNotificationAction(identifier: "RECORD_VISIT", title: "Record Visit", options: .foreground),
                UNNotificationAction(identifier: "VIEW_COMPLIANCE", title: "View Compliance", options: .foreground)
            ],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        categories.insert(taxHomeCategory)

        // Expense reminder category
        let expenseCategory = UNNotificationCategory(
            identifier: NotificationType.expenseReminder.categoryIdentifier,
            actions: [
                UNNotificationAction(identifier: "ADD_EXPENSE", title: "Add Expense", options: .foreground),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        categories.insert(expenseCategory)

        notificationCenter.setNotificationCategories(categories)
    }

    // MARK: - Schedule Notifications

    /// Schedule a generic notification
    public func scheduleNotification(
        type: NotificationType,
        body: String,
        triggerDate: Date,
        identifier: String? = nil
    ) async {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.categoryIdentifier

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let id = identifier ?? "\(type.rawValue)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            ServiceLogger.logSuccess("Scheduled notification: \(id) for \(triggerDate)", category: .notification)
        } catch {
            ServiceLogger.log("Failed to schedule notification", category: .notification, level: .error, error: error)
        }
    }

    // MARK: - Tax Deadline Reminders

    /// Schedule quarterly tax deadline reminders for the year
    public func scheduleTaxDeadlineReminders(for year: Int) async {
        // IRS quarterly payment due dates
        let deadlines: [(quarter: String, month: Int, day: Int, forQuarter: String)] = [
            ("Q1", 4, 15, "Q1"),      // Apr 15 for Q1 income
            ("Q2", 6, 15, "Q2"),      // Jun 15 for Q2 income
            ("Q3", 9, 15, "Q3"),      // Sep 15 for Q3 income
            ("Q4", 1, 15, "Q4")       // Jan 15 (next year) for Q4 income
        ]

        for deadline in deadlines {
            let deadlineYear = deadline.quarter == "Q4" ? year + 1 : year

            guard let dueDate = Calendar.current.date(from: DateComponents(
                year: deadlineYear,
                month: deadline.month,
                day: deadline.day,
                hour: 9,
                minute: 0
            )) else { continue }

            // Skip if the date has already passed
            guard dueDate > Date() else { continue }

            // Schedule reminder 7 days before
            if let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: dueDate),
               reminderDate > Date() {
                await scheduleNotification(
                    type: .taxDeadline,
                    body: "Your \(deadline.forQuarter) estimated tax payment is due in 7 days on \(formatDate(dueDate)).",
                    triggerDate: reminderDate,
                    identifier: "tax_deadline_\(year)_\(deadline.quarter)_7day"
                )
            }

            // Schedule reminder 1 day before
            if let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate),
               reminderDate > Date() {
                await scheduleNotification(
                    type: .taxDeadline,
                    body: "Your \(deadline.forQuarter) estimated tax payment is due TOMORROW.",
                    triggerDate: reminderDate,
                    identifier: "tax_deadline_\(year)_\(deadline.quarter)_1day"
                )
            }

            // Schedule reminder on due date
            await scheduleNotification(
                type: .taxDeadline,
                body: "Your \(deadline.forQuarter) estimated tax payment is due TODAY.",
                triggerDate: dueDate,
                identifier: "tax_deadline_\(year)_\(deadline.quarter)_due"
            )
        }
    }

    // MARK: - Assignment Reminders

    /// Schedule reminders for an assignment
    public func scheduleAssignmentReminders(
        assignmentId: UUID,
        facilityName: String,
        startDate: Date,
        endDate: Date
    ) async {
        let idPrefix = "assignment_\(assignmentId.uuidString)"

        // Reminder 3 days before start
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: startDate),
           reminderDate > Date() {
            await scheduleNotification(
                type: .assignmentStart,
                body: "Your assignment at \(facilityName) starts in 3 days!",
                triggerDate: reminderDate,
                identifier: "\(idPrefix)_start_3day"
            )
        }

        // Reminder on start date
        if startDate > Date() {
            var startComponents = Calendar.current.dateComponents([.year, .month, .day], from: startDate)
            startComponents.hour = 7
            startComponents.minute = 0
            if let morningStart = Calendar.current.date(from: startComponents) {
                await scheduleNotification(
                    type: .assignmentStart,
                    body: "Your assignment at \(facilityName) starts today! Good luck!",
                    triggerDate: morningStart,
                    identifier: "\(idPrefix)_start_day"
                )
            }
        }

        // Reminder 2 weeks before end
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate),
           reminderDate > Date() {
            await scheduleNotification(
                type: .assignmentEnd,
                body: "Your assignment at \(facilityName) ends in 2 weeks. Time to plan your next move!",
                triggerDate: reminderDate,
                identifier: "\(idPrefix)_end_14day"
            )
        }

        // Reminder 3 days before end
        if let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: endDate),
           reminderDate > Date() {
            await scheduleNotification(
                type: .assignmentEnd,
                body: "Your assignment at \(facilityName) ends in 3 days.",
                triggerDate: reminderDate,
                identifier: "\(idPrefix)_end_3day"
            )
        }

        // Schedule milestone reminders (halfway point)
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        if totalDays > 14,
           let halfwayDate = Calendar.current.date(byAdding: .day, value: totalDays / 2, to: startDate),
           halfwayDate > Date() {
            await scheduleNotification(
                type: .assignmentMilestone,
                body: "You're halfway through your assignment at \(facilityName)! Keep up the great work!",
                triggerDate: halfwayDate,
                identifier: "\(idPrefix)_milestone_halfway"
            )
        }
    }

    // MARK: - Tax Home Reminders

    /// Schedule tax home visit reminder based on 30-day rule
    public func scheduleTaxHomeReminder(daysUntilRequired: Int) async {
        guard daysUntilRequired > 0 else { return }

        // Cancel any existing tax home reminders
        await cancelNotifications(ofType: .taxHomeReminder)

        // Schedule reminder when 7 days remain
        if daysUntilRequired > 7 {
            let daysUntilReminder = daysUntilRequired - 7
            if let reminderDate = Calendar.current.date(byAdding: .day, value: daysUntilReminder, to: Date()) {
                await scheduleNotification(
                    type: .taxHomeReminder,
                    body: "You need to visit your tax home within the next 7 days to maintain IRS compliance.",
                    triggerDate: reminderDate,
                    identifier: "tax_home_7day"
                )
            }
        }

        // Schedule urgent reminder when 3 days remain
        if daysUntilRequired > 3 {
            let daysUntilReminder = daysUntilRequired - 3
            if let reminderDate = Calendar.current.date(byAdding: .day, value: daysUntilReminder, to: Date()) {
                await scheduleNotification(
                    type: .taxHomeReminder,
                    body: "URGENT: Only 3 days left to visit your tax home. Schedule your trip now!",
                    triggerDate: reminderDate,
                    identifier: "tax_home_3day"
                )
            }
        }

        // Schedule final warning when 1 day remains
        if daysUntilRequired > 1 {
            let daysUntilReminder = daysUntilRequired - 1
            if let reminderDate = Calendar.current.date(byAdding: .day, value: daysUntilReminder, to: Date()) {
                await scheduleNotification(
                    type: .taxHomeReminder,
                    body: "CRITICAL: Visit your tax home TOMORROW to avoid losing your tax-free stipends!",
                    triggerDate: reminderDate,
                    identifier: "tax_home_1day"
                )
            }
        }
    }

    // MARK: - One-Year Rule Warning

    /// Schedule warning for IRS one-year rule
    public func scheduleOneYearRuleWarning(
        assignmentId: UUID,
        facilityName: String,
        daysWorked: Int
    ) async {
        let idPrefix = "one_year_\(assignmentId.uuidString)"

        // Warn at 300 days (65 days before the limit)
        if daysWorked < 300 {
            let daysUntil300 = 300 - daysWorked
            if let warningDate = Calendar.current.date(byAdding: .day, value: daysUntil300, to: Date()) {
                await scheduleNotification(
                    type: .oneYearRule,
                    body: "You've worked 300 days at \(facilityName). The IRS one-year rule limit is 365 days.",
                    triggerDate: warningDate,
                    identifier: "\(idPrefix)_300days"
                )
            }
        }

        // Warn at 330 days (35 days before the limit)
        if daysWorked < 330 {
            let daysUntil330 = 330 - daysWorked
            if let warningDate = Calendar.current.date(byAdding: .day, value: daysUntil330, to: Date()) {
                await scheduleNotification(
                    type: .oneYearRule,
                    body: "Warning: 330 days at \(facilityName). Only 35 days left before one-year rule applies!",
                    triggerDate: warningDate,
                    identifier: "\(idPrefix)_330days"
                )
            }
        }

        // Critical warning at 350 days
        if daysWorked < 350 {
            let daysUntil350 = 350 - daysWorked
            if let warningDate = Calendar.current.date(byAdding: .day, value: daysUntil350, to: Date()) {
                await scheduleNotification(
                    type: .oneYearRule,
                    body: "CRITICAL: 350 days at \(facilityName). Plan to end this assignment soon to protect your stipends!",
                    triggerDate: warningDate,
                    identifier: "\(idPrefix)_350days"
                )
            }
        }
    }

    // MARK: - Weekly Expense Reminder

    /// Schedule weekly expense logging reminder
    public func scheduleWeeklyExpenseReminder() async {
        // Cancel existing weekly reminders
        await cancelNotifications(ofType: .expenseReminder)

        // Schedule for every Sunday at 7 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = NotificationType.expenseReminder.title
        content.body = "Don't forget to log your expenses from this week! Keeping track helps maximize your deductions."
        content.sound = .default
        content.categoryIdentifier = NotificationType.expenseReminder.categoryIdentifier

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "expense_reminder_weekly",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            ServiceLogger.logSuccess("Scheduled weekly expense reminder", category: .notification)
        } catch {
            ServiceLogger.log("Failed to schedule weekly expense reminder", category: .notification, level: .error, error: error)
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel a specific notification by identifier
    public func cancelNotification(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    /// Cancel all notifications
    public func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Cancel all notifications of a specific type
    public func cancelNotifications(ofType type: NotificationType) async {
        let pending = await getPendingNotifications()
        let identifiersToRemove = pending
            .filter { $0.identifier.hasPrefix(type.rawValue) || $0.content.categoryIdentifier == type.categoryIdentifier }
            .map { $0.identifier }

        if !identifiersToRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }

    /// Cancel all notifications for a specific assignment
    public func cancelAssignmentNotifications(assignmentId: UUID) async {
        let prefix = "assignment_\(assignmentId.uuidString)"
        let oneYearPrefix = "one_year_\(assignmentId.uuidString)"

        let pending = await getPendingNotifications()
        let identifiersToRemove = pending
            .filter { $0.identifier.hasPrefix(prefix) || $0.identifier.hasPrefix(oneYearPrefix) }
            .map { $0.identifier }

        if !identifiersToRemove.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }

    // MARK: - Query Notifications

    /// Get all pending notification requests
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Convenience Methods for Services

    /// Schedule a notification with custom title (non-async convenience wrapper)
    /// Used by LicenseService and QuarterlyPaymentService
    public func scheduleNotification(id: String, title: String, body: String, date: Date) {
        Task {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            do {
                try await notificationCenter.add(request)
                ServiceLogger.logSuccess("Scheduled notification: \(id) for \(date)", category: .notification)
            } catch {
                ServiceLogger.log("Failed to schedule notification: \(id)", category: .notification, level: .error, error: error)
            }
        }
    }

    /// Cancel multiple notifications by identifiers (non-async convenience wrapper)
    /// Used by LicenseService and QuarterlyPaymentService
    public func cancelNotifications(ids: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ids)
    }
}
