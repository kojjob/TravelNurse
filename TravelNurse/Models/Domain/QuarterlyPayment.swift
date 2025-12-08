//
//  QuarterlyPayment.swift
//  TravelNurse
//
//  Persistent model for tracking quarterly estimated tax payments
//

import Foundation
import SwiftData

/// A quarterly estimated tax payment record
@Model
public final class QuarterlyPayment {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// Tax year this payment belongs to
    public var taxYear: Int

    /// Quarter number (1-4)
    public var quarter: Int

    /// Due date for this payment
    public var dueDate: Date

    /// Estimated amount to pay
    public var estimatedAmount: Decimal

    /// Actual amount paid
    public var paidAmount: Decimal

    /// Whether payment has been made
    public var isPaid: Bool

    /// Date payment was made
    public var paidDate: Date?

    /// Payment method notes (check number, confirmation, etc.)
    public var paymentNotes: String?

    /// Federal payment amount
    public var federalPayment: Decimal

    /// State payment amount
    public var statePayment: Decimal

    /// State for state tax payment
    public var stateRaw: String?

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Quarter display name (Q1, Q2, Q3, Q4)
    public var quarterName: String {
        "Q\(quarter)"
    }

    /// Full display name with year
    public var fullName: String {
        "Q\(quarter) \(taxYear)"
    }

    /// State as enum
    public var state: USState? {
        get {
            guard let raw = stateRaw else { return nil }
            return USState(rawValue: raw)
        }
        set {
            stateRaw = newValue?.rawValue
        }
    }

    /// Remaining amount to pay
    public var remainingAmount: Decimal {
        max(0, estimatedAmount - paidAmount)
    }

    /// Whether payment is overdue
    public var isOverdue: Bool {
        !isPaid && Date() > dueDate
    }

    /// Days until due (negative if overdue)
    public var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    /// Payment status
    public var status: PaymentStatus {
        if isPaid { return .paid }
        if isOverdue { return .overdue }
        if daysUntilDue <= 14 { return .dueSoon }
        if daysUntilDue <= 30 { return .upcoming }
        return .scheduled
    }

    /// Formatted due date
    @MainActor public var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: dueDate)
    }

    /// Formatted estimated amount
    @MainActor public var formattedEstimatedAmount: String {
        TNFormatters.currency(estimatedAmount)
    }

    /// Formatted paid amount
    @MainActor public var formattedPaidAmount: String {
        TNFormatters.currency(paidAmount)
    }

    /// Formatted remaining amount
    @MainActor public var formattedRemainingAmount: String {
        TNFormatters.currency(remainingAmount)
    }

    // MARK: - Initializer

    public init(
        taxYear: Int,
        quarter: Int,
        dueDate: Date,
        estimatedAmount: Decimal,
        federalPayment: Decimal = 0,
        statePayment: Decimal = 0,
        state: USState? = nil
    ) {
        self.id = UUID()
        self.taxYear = taxYear
        self.quarter = quarter
        self.dueDate = dueDate
        self.estimatedAmount = estimatedAmount
        self.paidAmount = 0
        self.isPaid = false
        self.federalPayment = federalPayment
        self.statePayment = statePayment
        self.stateRaw = state?.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// Record a payment
    public func recordPayment(amount: Decimal, notes: String? = nil) {
        self.paidAmount = amount
        self.isPaid = amount >= estimatedAmount
        self.paidDate = Date()
        self.paymentNotes = notes
        self.updatedAt = Date()
    }

    /// Update estimated amount
    public func updateEstimate(amount: Decimal, federal: Decimal, state: Decimal) {
        self.estimatedAmount = amount
        self.federalPayment = federal
        self.statePayment = state
        self.updatedAt = Date()
    }
}

// MARK: - Payment Status

public enum PaymentStatus: String, CaseIterable {
    case paid
    case overdue
    case dueSoon
    case upcoming
    case scheduled

    public var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .dueSoon: return "Due Soon"
        case .upcoming: return "Upcoming"
        case .scheduled: return "Scheduled"
        }
    }

    public var iconName: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .upcoming: return "calendar.badge.clock"
        case .scheduled: return "calendar"
        }
    }
}

// MARK: - Queries

extension QuarterlyPayment {
    /// Predicate for filtering by tax year
    static func yearPredicate(_ year: Int) -> Predicate<QuarterlyPayment> {
        #Predicate<QuarterlyPayment> { payment in
            payment.taxYear == year
        }
    }

    /// Predicate for unpaid payments
    static var unpaidPredicate: Predicate<QuarterlyPayment> {
        #Predicate<QuarterlyPayment> { payment in
            payment.isPaid == false
        }
    }

    /// Predicate for overdue payments
    static func overduePredicate(asOf date: Date) -> Predicate<QuarterlyPayment> {
        #Predicate<QuarterlyPayment> { payment in
            payment.isPaid == false && payment.dueDate < date
        }
    }
}

// MARK: - Static Helpers

extension QuarterlyPayment {
    /// Standard IRS quarterly due dates for a given year
    static func standardDueDates(for year: Int) -> [(quarter: Int, date: Date)] {
        let calendar = Calendar.current
        return [
            (1, calendar.date(from: DateComponents(year: year, month: 4, day: 15)) ?? Date()),
            (2, calendar.date(from: DateComponents(year: year, month: 6, day: 15)) ?? Date()),
            (3, calendar.date(from: DateComponents(year: year, month: 9, day: 15)) ?? Date()),
            (4, calendar.date(from: DateComponents(year: year + 1, month: 1, day: 15)) ?? Date())
        ]
    }

    /// Create quarterly payments for a year with estimated amounts
    static func createForYear(
        _ year: Int,
        totalEstimatedTax: Decimal,
        federalTax: Decimal,
        stateTax: Decimal,
        state: USState?
    ) -> [QuarterlyPayment] {
        let quarterlyTotal = totalEstimatedTax / 4
        let quarterlyFederal = federalTax / 4
        let quarterlyState = stateTax / 4

        return standardDueDates(for: year).map { quarterInfo in
            QuarterlyPayment(
                taxYear: year,
                quarter: quarterInfo.quarter,
                dueDate: quarterInfo.date,
                estimatedAmount: quarterlyTotal,
                federalPayment: quarterlyFederal,
                statePayment: quarterlyState,
                state: state
            )
        }
    }
}

// MARK: - Preview Helper

extension QuarterlyPayment {
    static var preview: QuarterlyPayment {
        let year = Calendar.current.component(.year, from: Date())
        let dueDate = Calendar.current.date(from: DateComponents(year: year, month: 6, day: 15)) ?? Date()
        return QuarterlyPayment(
            taxYear: year,
            quarter: 2,
            dueDate: dueDate,
            estimatedAmount: 3500,
            federalPayment: 2800,
            statePayment: 700,
            state: .california
        )
    }

    static var previews: [QuarterlyPayment] {
        let year = Calendar.current.component(.year, from: Date())
        return QuarterlyPayment.createForYear(
            year,
            totalEstimatedTax: 14000,
            federalTax: 11200,
            stateTax: 2800,
            state: .california
        )
    }
}
