//
//  QuarterlyPaymentService.swift
//  TravelNurse
//
//  Service for managing quarterly estimated tax payments and reminders
//

import Foundation
import SwiftData

/// Service for managing quarterly estimated tax payments
@MainActor
public final class QuarterlyPaymentService {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let taxCalculationService: TaxCalculationService
    private let notificationService: NotificationService?

    // MARK: - Notification Configuration

    /// Days before due date to send first reminder
    private let firstReminderDays = 14

    /// Days before due date to send second reminder
    private let secondReminderDays = 7

    /// Days before due date to send final reminder
    private let finalReminderDays = 1

    // MARK: - Initialization

    public init(
        modelContext: ModelContext,
        taxCalculationService: TaxCalculationService,
        notificationService: NotificationService? = nil
    ) {
        self.modelContext = modelContext
        self.taxCalculationService = taxCalculationService
        self.notificationService = notificationService
    }

    // MARK: - Fetch Methods

    /// Fetch all quarterly payments for a year
    public func fetchPayments(for year: Int) -> [QuarterlyPayment] {
        let predicate = QuarterlyPayment.yearPredicate(year)
        let descriptor = FetchDescriptor<QuarterlyPayment>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.quarter)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching quarterly payments: \(error)")
            return []
        }
    }

    /// Fetch all unpaid payments
    public func fetchUnpaidPayments() -> [QuarterlyPayment] {
        let descriptor = FetchDescriptor<QuarterlyPayment>(
            predicate: QuarterlyPayment.unpaidPredicate,
            sortBy: [SortDescriptor(\.dueDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching unpaid payments: \(error)")
            return []
        }
    }

    /// Fetch overdue payments
    public func fetchOverduePayments() -> [QuarterlyPayment] {
        let now = Date()
        let predicate = QuarterlyPayment.overduePredicate(asOf: now)
        let descriptor = FetchDescriptor<QuarterlyPayment>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.dueDate)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching overdue payments: \(error)")
            return []
        }
    }

    /// Get the next upcoming payment
    public func nextUpcomingPayment() -> QuarterlyPayment? {
        let now = Date()
        let descriptor = FetchDescriptor<QuarterlyPayment>(
            predicate: #Predicate<QuarterlyPayment> { payment in
                payment.isPaid == false && payment.dueDate >= now
            },
            sortBy: [SortDescriptor(\.dueDate)]
        )

        do {
            let payments = try modelContext.fetch(descriptor)
            return payments.first
        } catch {
            print("Error fetching next payment: \(error)")
            return nil
        }
    }

    // MARK: - Create/Update Methods

    /// Generate or update quarterly payments for a year based on income
    public func generatePayments(
        for year: Int,
        grossIncome: Decimal,
        deductions: Decimal,
        state: USState,
        isSelfEmployed: Bool = true
    ) -> [QuarterlyPayment] {
        // Calculate tax estimate
        let taxResult = taxCalculationService.calculateTotalTax(
            grossIncome: grossIncome,
            deductions: deductions,
            state: state,
            isSelfEmployed: isSelfEmployed
        )

        // Check for existing payments
        let existingPayments = fetchPayments(for: year)

        if existingPayments.isEmpty {
            // Create new payments
            let payments = QuarterlyPayment.createForYear(
                year,
                totalEstimatedTax: taxResult.totalTax,
                federalTax: taxResult.federalTax,
                stateTax: taxResult.stateTax,
                state: state
            )

            // Insert into context
            for payment in payments {
                modelContext.insert(payment)
            }

            // Schedule notifications
            scheduleReminders(for: payments)

            saveContext()
            return payments
        } else {
            // Update existing payments that haven't been paid
            let quarterlyTotal = taxResult.totalTax / 4
            let quarterlyFederal = taxResult.federalTax / 4
            let quarterlyState = taxResult.stateTax / 4

            for payment in existingPayments where !payment.isPaid {
                payment.updateEstimate(
                    amount: quarterlyTotal,
                    federal: quarterlyFederal,
                    state: quarterlyState
                )
            }

            // Re-schedule reminders for unpaid
            let unpaid = existingPayments.filter { !$0.isPaid }
            scheduleReminders(for: unpaid)

            saveContext()
            return existingPayments
        }
    }

    /// Record a payment for a quarter
    public func recordPayment(
        _ payment: QuarterlyPayment,
        amount: Decimal,
        notes: String? = nil
    ) {
        payment.recordPayment(amount: amount, notes: notes)

        // Cancel reminders for this payment
        cancelReminders(for: payment)

        saveContext()
    }

    /// Delete a payment
    public func deletePayment(_ payment: QuarterlyPayment) {
        cancelReminders(for: payment)
        modelContext.delete(payment)
        saveContext()
    }

    // MARK: - Notification Methods

    /// Schedule reminders for quarterly payments
    public func scheduleReminders(for payments: [QuarterlyPayment]) {
        guard let notificationService = notificationService else { return }

        for payment in payments where !payment.isPaid {
            scheduleRemindersForPayment(payment, using: notificationService)
        }
    }

    private func scheduleRemindersForPayment(_ payment: QuarterlyPayment, using service: NotificationService) {
        let calendar = Calendar.current

        // First reminder (14 days before)
        if let firstDate = calendar.date(byAdding: .day, value: -firstReminderDays, to: payment.dueDate),
           firstDate > Date() {
            service.scheduleNotification(
                id: "\(payment.id)-reminder-14",
                title: "Tax Payment Reminder",
                body: "\(payment.quarterName) \(payment.taxYear) estimated tax payment of \(formatCurrency(payment.estimatedAmount)) is due in 2 weeks.",
                date: firstDate
            )
        }

        // Second reminder (7 days before)
        if let secondDate = calendar.date(byAdding: .day, value: -secondReminderDays, to: payment.dueDate),
           secondDate > Date() {
            service.scheduleNotification(
                id: "\(payment.id)-reminder-7",
                title: "Tax Payment Due Soon",
                body: "\(payment.quarterName) \(payment.taxYear) estimated tax payment of \(formatCurrency(payment.estimatedAmount)) is due in 1 week.",
                date: secondDate
            )
        }

        // Final reminder (1 day before)
        if let finalDate = calendar.date(byAdding: .day, value: -finalReminderDays, to: payment.dueDate),
           finalDate > Date() {
            service.scheduleNotification(
                id: "\(payment.id)-reminder-1",
                title: "Tax Payment Due Tomorrow!",
                body: "\(payment.quarterName) \(payment.taxYear) estimated tax payment of \(formatCurrency(payment.estimatedAmount)) is due tomorrow.",
                date: finalDate
            )
        }

        // Due date reminder
        if payment.dueDate > Date() {
            var components = calendar.dateComponents([.year, .month, .day], from: payment.dueDate)
            components.hour = 9
            components.minute = 0
            if let dueDateTime = calendar.date(from: components) {
                service.scheduleNotification(
                    id: "\(payment.id)-due",
                    title: "Tax Payment Due Today",
                    body: "\(payment.quarterName) \(payment.taxYear) estimated tax payment of \(formatCurrency(payment.estimatedAmount)) is due today!",
                    date: dueDateTime
                )
            }
        }
    }

    /// Cancel reminders for a payment
    public func cancelReminders(for payment: QuarterlyPayment) {
        guard let notificationService = notificationService else { return }

        let ids = [
            "\(payment.id)-reminder-14",
            "\(payment.id)-reminder-7",
            "\(payment.id)-reminder-1",
            "\(payment.id)-due"
        ]

        notificationService.cancelNotifications(ids: ids)
    }

    /// Cancel all quarterly payment reminders
    public func cancelAllReminders() {
        guard let notificationService = notificationService else { return }

        let allPayments = fetchUnpaidPayments()
        for payment in allPayments {
            cancelReminders(for: payment)
        }
    }

    // MARK: - Summary Methods

    /// Get payment summary for a year
    public func paymentSummary(for year: Int) -> PaymentSummary {
        let payments = fetchPayments(for: year)

        let totalEstimated = payments.reduce(Decimal(0)) { $0 + $1.estimatedAmount }
        let totalPaid = payments.reduce(Decimal(0)) { $0 + $1.paidAmount }
        let paidCount = payments.filter { $0.isPaid }.count
        let overdueCount = payments.filter { $0.isOverdue }.count

        return PaymentSummary(
            year: year,
            totalEstimated: totalEstimated,
            totalPaid: totalPaid,
            remaining: totalEstimated - totalPaid,
            quartersPaid: paidCount,
            quartersOverdue: overdueCount,
            payments: payments
        )
    }

    // MARK: - Helpers

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Payment Summary

public struct PaymentSummary {
    public let year: Int
    public let totalEstimated: Decimal
    public let totalPaid: Decimal
    public let remaining: Decimal
    public let quartersPaid: Int
    public let quartersOverdue: Int
    public let payments: [QuarterlyPayment]

    public var progress: Double {
        guard totalEstimated > 0 else { return 0 }
        return (totalPaid as NSDecimalNumber).doubleValue / (totalEstimated as NSDecimalNumber).doubleValue
    }

    public var isFullyPaid: Bool {
        quartersPaid == 4
    }

    public var hasOverdue: Bool {
        quartersOverdue > 0
    }

    public var formattedTotalEstimated: String {
        formatCurrency(totalEstimated)
    }

    public var formattedTotalPaid: String {
        formatCurrency(totalPaid)
    }

    public var formattedRemaining: String {
        formatCurrency(remaining)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}
