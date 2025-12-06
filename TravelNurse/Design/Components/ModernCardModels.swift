//
//  ModernCardModels.swift
//  TravelNurse
//
//  Data models for modern UI card components
//

import SwiftUI

// MARK: - Badge Status Types

/// Status types for badges throughout the app
public enum BadgeStatus: String, Equatable {
    case dueSoon = "Due Date"
    case unpaid = "Not Paid"
    case paid = "Paid"
    case active = "Active"
    case disabled = "Disabled"
    case pending = "Pending"
    case moneyIn = "Money In"
    case moneyOut = "Money Out"

    var color: Color {
        switch self {
        case .dueSoon:
            return TNColors.warning
        case .unpaid:
            return TNColors.error
        case .paid:
            return TNColors.success
        case .active:
            return TNColors.success
        case .disabled:
            return TNColors.disabled
        case .pending:
            return TNColors.warning
        case .moneyIn:
            return TNColors.success
        case .moneyOut:
            return TNColors.error
        }
    }

    var backgroundColor: Color {
        color.opacity(0.12)
    }
}

/// Frequency for recurring items
public enum PaymentFrequency: String {
    case monthly = "/month"
    case weekly = "/week"
    case yearly = "/year"
    case once = ""
}

/// Transaction type
public enum TransactionType {
    case income
    case expense
}

// MARK: - Status Badge Component Data

/// Data for status badge component
public struct TNStatusBadge: Equatable {
    public let status: BadgeStatus
    public let text: String

    public init(status: BadgeStatus, text: String) {
        self.status = status
        self.text = text
    }
}

// MARK: - Quick Menu Item Data

/// Data for quick menu item (bills, subscriptions)
public struct QuickMenuItemData: Identifiable, Equatable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let amount: Double
    public let frequency: PaymentFrequency
    public let status: BadgeStatus

    public init(
        icon: String,
        title: String,
        amount: Double,
        frequency: PaymentFrequency,
        status: BadgeStatus
    ) {
        self.icon = icon
        self.title = title
        self.amount = amount
        self.frequency = frequency
        self.status = status
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return (formatter.string(from: NSNumber(value: amount)) ?? "$0.00") + frequency.rawValue
    }

    public static func == (lhs: QuickMenuItemData, rhs: QuickMenuItemData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Finance Health Data

/// Data for finance health visualization card
public struct FinanceHealthData {
    public let title: String
    public let subtitle: String
    public let savedAmount: Double
    public let progressBars: Int
    public let filledBars: Int

    public init(
        title: String,
        subtitle: String,
        savedAmount: Double,
        progressBars: Int,
        filledBars: Int
    ) {
        self.title = title
        self.subtitle = subtitle
        self.savedAmount = savedAmount
        self.progressBars = progressBars
        self.filledBars = filledBars
    }

    public var progressPercentage: Double {
        guard progressBars > 0 else { return 0 }
        return Double(filledBars) / Double(progressBars)
    }

    public var formattedSavedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: savedAmount)) ?? "$0.00"
    }
}

// MARK: - Balance Card Data

/// Data for main balance display card
public struct BalanceCardData {
    public let title: String
    public let amount: Double
    public let changePercentage: Double
    public let changeAmount: Double
    public let isPositive: Bool

    public init(
        title: String,
        amount: Double,
        changePercentage: Double,
        changeAmount: Double,
        isPositive: Bool
    ) {
        self.title = title
        self.amount = amount
        self.changePercentage = changePercentage
        self.changeAmount = changeAmount
        self.isPositive = isPositive
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    public var formattedChange: String {
        let sign = isPositive ? "+" : "-"
        return "\(sign)\(Int(abs(changePercentage)))%"
    }

    public var formattedChangeAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        let prefix = isPositive ? "Receive " : "Spent "
        return prefix + (formatter.string(from: NSNumber(value: changeAmount)) ?? "$0.00") + " this month."
    }
}

// MARK: - Deadline Reminder Data

/// Data for deadline/bill reminder card
public struct DeadlineReminderData {
    public let icon: String
    public let iconBackgroundColor: Color
    public let amount: Double
    public let title: String
    public let dueDate: Date
    public let actionTitle: String

    public init(
        icon: String,
        iconBackgroundColor: Color,
        amount: Double,
        title: String,
        dueDate: Date,
        actionTitle: String
    ) {
        self.icon = icon
        self.iconBackgroundColor = iconBackgroundColor
        self.amount = amount
        self.title = title
        self.dueDate = dueDate
        self.actionTitle = actionTitle
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    public var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return "Due today, " + formatter.string(from: dueDate)
    }
}

// MARK: - Transaction Data

/// Data for transaction row
public struct TransactionData: Identifiable, Equatable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let amount: Double
    public let type: TransactionType
    public let status: BadgeStatus

    public init(
        icon: String,
        title: String,
        amount: Double,
        type: TransactionType,
        status: BadgeStatus
    ) {
        self.icon = icon
        self.title = title
        self.amount = amount
        self.type = type
        self.status = status
    }

    public var isPositive: Bool {
        type == .income
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        let prefix = isPositive ? "" : "-"
        return prefix + (formatter.string(from: NSNumber(value: amount)) ?? "$0.00")
    }

    public static func == (lhs: TransactionData, rhs: TransactionData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Assignment Card Data

/// Data for visual assignment card (credit card style)
public struct AssignmentCardData: Identifiable, Equatable {
    public let id = UUID()
    public let facilityName: String
    public let location: String
    public let amount: Double
    public let cardType: String
    public let lastFourDigits: String
    public let expiryDate: String
    public let status: BadgeStatus
    public let cardColor: Color

    public init(
        facilityName: String,
        location: String,
        amount: Double,
        cardType: String,
        lastFourDigits: String,
        expiryDate: String,
        status: BadgeStatus,
        cardColor: Color
    ) {
        self.facilityName = facilityName
        self.location = location
        self.amount = amount
        self.cardType = cardType
        self.lastFourDigits = lastFourDigits
        self.expiryDate = expiryDate
        self.status = status
        self.cardColor = cardColor
    }

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    public static func == (lhs: AssignmentCardData, rhs: AssignmentCardData) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Expenses Summary Data

/// Data for expenses summary card with comparison
public struct ExpensesSummaryData {
    public let title: String
    public let currentAmount: Double
    public let previousAmount: Double
    public let comparisonPercentage: Double
    public let comparisonLabel: String

    public init(
        title: String,
        currentAmount: Double,
        previousAmount: Double,
        comparisonPercentage: Double,
        comparisonLabel: String
    ) {
        self.title = title
        self.currentAmount = currentAmount
        self.previousAmount = previousAmount
        self.comparisonPercentage = comparisonPercentage
        self.comparisonLabel = comparisonLabel
    }

    public var isDecrease: Bool {
        comparisonPercentage < 0
    }

    public var formattedCurrentAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: currentAmount)) ?? "$0.00"
    }

    public var formattedPreviousAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: previousAmount)) ?? "$0.00"
    }

    public var formattedPercentage: String {
        let sign = comparisonPercentage < 0 ? "" : "+"
        return "\(sign)\(Int(comparisonPercentage))%"
    }
}
