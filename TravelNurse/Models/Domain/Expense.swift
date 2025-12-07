//
//  Expense.swift
//  TravelNurse
//
//  Expense tracking model for tax deductions
//

import Foundation
import SwiftData

/// A tax-deductible expense entry
@Model
public final class Expense {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// Associated assignment (optional - some expenses aren't assignment-specific)
    public var assignment: Assignment?

    /// Expense category (raw value for persistence)
    public var categoryRaw: String

    /// Expense amount
    public var amount: Decimal

    /// Date of expense
    public var date: Date

    /// Merchant/vendor name
    public var merchantName: String?

    /// Description or notes
    public var notes: String?

    /// Associated receipt
    @Relationship(deleteRule: .cascade)
    public var receipt: Receipt?

    /// Whether this expense is tax deductible
    public var isDeductible: Bool

    /// Tax year this expense belongs to
    public var taxYear: Int

    /// Whether this has been exported/reported
    public var isReported: Bool

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

    /// Whether receipt is attached
    public var hasReceipt: Bool {
        receipt != nil
    }

    /// Formatted amount string
    public var amountFormatted: String {
        TNFormatters.currency(amount)
    }

    /// Formatted date string
    public var dateFormatted: String {
        TNFormatters.date(date)
    }

    /// Short description for lists
    public var shortDescription: String {
        if let merchant = merchantName, !merchant.isEmpty {
            return merchant
        }
        return category.displayName
    }

    // MARK: - Initializer

    public init(
        category: ExpenseCategory,
        amount: Decimal,
        date: Date = Date(),
        merchantName: String? = nil,
        notes: String? = nil,
        isDeductible: Bool = true
    ) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.date = date
        self.merchantName = merchantName
        self.notes = notes
        self.isDeductible = isDeductible
        self.taxYear = Calendar.current.component(.year, from: date)
        self.isReported = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Expense Queries

extension Expense {
    /// Create a predicate for filtering by tax year
    static func taxYearPredicate(_ year: Int) -> Predicate<Expense> {
        #Predicate<Expense> { expense in
            expense.taxYear == year
        }
    }

    /// Create a predicate for filtering by category
    static func categoryPredicate(_ category: ExpenseCategory) -> Predicate<Expense> {
        let categoryRaw = category.rawValue
        return #Predicate<Expense> { expense in
            expense.categoryRaw == categoryRaw
        }
    }

    /// Create a predicate for deductible expenses only
    static var deductiblePredicate: Predicate<Expense> {
        #Predicate<Expense> { expense in
            expense.isDeductible == true
        }
    }
}

// MARK: - Preview Helper

extension Expense {
    /// Sample expense for SwiftUI previews
    static var preview: Expense {
        let expense = Expense(
            category: .meals,
            amount: 45.99,
            date: Date(),
            merchantName: "Whole Foods Market",
            notes: "Groceries for the week",
            isDeductible: true
        )
        return expense
    }

    /// Sample expenses array for previews
    static var previews: [Expense] {
        [
            Expense(
                category: .meals,
                amount: 45.99,
                date: Date(),
                merchantName: "Whole Foods Market",
                isDeductible: true
            ),
            Expense(
                category: .gasoline,
                amount: 68.50,
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                merchantName: "Shell Gas Station",
                isDeductible: true
            ),
            Expense(
                category: .licensure,
                amount: 150.00,
                date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                merchantName: "State Board of Nursing",
                isDeductible: true
            ),
            Expense(
                category: .uniformsScrubs,
                amount: 89.00,
                date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                merchantName: "Cherokee Uniforms",
                isDeductible: true
            )
        ]
    }
}
