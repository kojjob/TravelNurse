//
//  RecurringExpense.swift
//  TravelNurse
//
//  Model for recurring/repeating expenses (rent, phone, subscriptions, etc.)
//

import Foundation
import SwiftData

// MARK: - Recurrence Frequency

/// How often a recurring expense repeats
public enum RecurrenceFrequency: String, CaseIterable, Codable, Identifiable, Sendable {
    case weekly
    case biweekly
    case monthly
    case quarterly
    case annually

    public var id: String { rawValue }

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .annually: return "Annually"
        }
    }

    /// Calendar component for date calculation
    public var calendarComponent: Calendar.Component {
        switch self {
        case .weekly, .biweekly: return .weekOfYear
        case .monthly: return .month
        case .quarterly: return .month
        case .annually: return .year
        }
    }

    /// Value to add for the calendar component
    public var componentValue: Int {
        switch self {
        case .weekly: return 1
        case .biweekly: return 2
        case .monthly: return 1
        case .quarterly: return 3
        case .annually: return 1
        }
    }

    /// Approximate occurrences per month (for monthly cost estimation)
    public var monthlyMultiplier: Decimal {
        switch self {
        case .weekly: return Decimal(52) / Decimal(12)  // ~4.33
        case .biweekly: return Decimal(26) / Decimal(12) // ~2.17
        case .monthly: return 1
        case .quarterly: return Decimal(1) / Decimal(3) // ~0.33
        case .annually: return Decimal(1) / Decimal(12) // ~0.083
        }
    }
}

// MARK: - Recurring Expense Model

/// A recurring expense that automatically generates expense entries
@Model
public final class RecurringExpense {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// Display name for this recurring expense
    public var name: String

    /// Expense category (raw value for persistence)
    public var categoryRaw: String

    /// Amount per occurrence
    public var amount: Decimal

    /// Recurrence frequency (raw value for persistence)
    public var frequencyRaw: String

    /// Start date for this recurring expense
    public var startDate: Date

    /// Optional end date (nil = indefinite)
    public var endDate: Date?

    /// Merchant/vendor name
    public var merchantName: String?

    /// Description or notes
    public var notes: String?

    /// Whether this recurring expense is currently active
    public var isActive: Bool

    /// Whether expenses from this are tax deductible
    public var isDeductible: Bool

    /// Date of last generated expense
    public var lastGeneratedDate: Date?

    /// Count of expenses generated from this recurring entry
    public var generatedCount: Int

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Category as enum
    public var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Frequency as enum
    public var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Calculate the next occurrence date
    public var nextOccurrence: Date? {
        guard isActive else { return nil }

        let calendar = Calendar.current
        var nextDate: Date

        if let lastDate = lastGeneratedDate {
            // Calculate next from last generated
            guard let next = calendar.date(
                byAdding: frequency.calendarComponent,
                value: frequency.componentValue,
                to: lastDate
            ) else { return nil }
            nextDate = next
        } else {
            // First occurrence is the start date
            nextDate = startDate
        }

        // Check if past end date
        if let end = endDate, nextDate > end {
            return nil
        }

        return nextDate
    }

    /// Whether this expense is due to be generated
    public var isDue: Bool {
        guard isActive, let next = nextOccurrence else { return false }
        return next <= Date()
    }

    /// Total amount generated from this recurring expense
    public var totalGenerated: Decimal {
        amount * Decimal(generatedCount)
    }

    /// Estimated monthly cost
    public var monthlyEstimate: Decimal {
        amount * frequency.monthlyMultiplier
    }

    /// Estimated annual cost
    public var annualEstimate: Decimal {
        monthlyEstimate * 12
    }

    /// Description of frequency and amount
    public var frequencyDescription: String {
        "\(frequency.displayName)"
    }

    /// Formatted amount
    @MainActor public var formattedAmount: String {
        TNFormatters.currency(amount)
    }

    /// Formatted monthly estimate
    @MainActor public var formattedMonthlyEstimate: String {
        TNFormatters.currency(monthlyEstimate)
    }

    /// Formatted next occurrence date
    @MainActor public var formattedNextOccurrence: String? {
        guard let next = nextOccurrence else { return nil }
        return TNFormatters.date(next)
    }

    // MARK: - Initializer

    public init(
        name: String,
        category: ExpenseCategory,
        amount: Decimal,
        frequency: RecurrenceFrequency,
        startDate: Date,
        merchantName: String? = nil,
        notes: String? = nil,
        isDeductible: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.startDate = startDate
        self.merchantName = merchantName
        self.notes = notes
        self.isActive = true
        self.isDeductible = isDeductible
        self.generatedCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// Pause this recurring expense
    public func pause() {
        isActive = false
        updatedAt = Date()
    }

    /// Resume this recurring expense
    public func resume() {
        isActive = true
        updatedAt = Date()
    }

    /// Record that an expense was generated
    public func recordGeneration(date: Date = Date()) {
        lastGeneratedDate = date
        generatedCount += 1
        updatedAt = Date()
    }
}

// MARK: - Queries

extension RecurringExpense {
    /// Predicate for active recurring expenses
    static var activePredicate: Predicate<RecurringExpense> {
        #Predicate<RecurringExpense> { expense in
            expense.isActive == true
        }
    }

    /// Predicate for filtering by category
    static func categoryPredicate(_ category: ExpenseCategory) -> Predicate<RecurringExpense> {
        let categoryRaw = category.rawValue
        return #Predicate<RecurringExpense> { expense in
            expense.categoryRaw == categoryRaw
        }
    }
}

// MARK: - Preview Helper

extension RecurringExpense {
    static var preview: RecurringExpense {
        RecurringExpense(
            name: "Monthly Rent",
            category: .rent,
            amount: 1500,
            frequency: .monthly,
            startDate: Date(),
            merchantName: "Property Management Co."
        )
    }

    static var previews: [RecurringExpense] {
        [
            RecurringExpense(
                name: "Assignment Housing",
                category: .rent,
                amount: 1800,
                frequency: .monthly,
                startDate: Date(),
                merchantName: "Furnished Finder"
            ),
            RecurringExpense(
                name: "Cell Phone",
                category: .cellPhone,
                amount: 85,
                frequency: .monthly,
                startDate: Date(),
                merchantName: "Verizon"
            ),
            RecurringExpense(
                name: "Internet",
                category: .internet,
                amount: 65,
                frequency: .monthly,
                startDate: Date(),
                merchantName: "Xfinity"
            ),
            RecurringExpense(
                name: "Professional Liability",
                category: .liability,
                amount: 200,
                frequency: .annually,
                startDate: Date(),
                merchantName: "NSO"
            )
        ]
    }
}
