//
//  Income.swift
//  TravelNurse
//
//  Ad-hoc income entries for bonuses, referrals, and other income outside assignments
//

import Foundation
import SwiftData

/// Income types for travel nurses
public enum IncomeType: String, Codable, CaseIterable, Identifiable {
    case bonus = "Bonus"
    case referralBonus = "Referral Bonus"
    case signOnBonus = "Sign-On Bonus"
    case completionBonus = "Completion Bonus"
    case perDiem = "Per Diem"
    case overtime = "Overtime"
    case holidayPay = "Holiday Pay"
    case stipendAdjustment = "Stipend Adjustment"
    case travelReimbursement = "Travel Reimbursement"
    case other = "Other"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .bonus, .signOnBonus, .completionBonus:
            return "star.fill"
        case .referralBonus:
            return "person.2.fill"
        case .perDiem:
            return "calendar.badge.clock"
        case .overtime:
            return "clock.badge.fill"
        case .holidayPay:
            return "gift.fill"
        case .stipendAdjustment:
            return "arrow.up.arrow.down"
        case .travelReimbursement:
            return "car.fill"
        case .other:
            return "dollarsign.circle.fill"
        }
    }

    /// Whether this income type is typically taxable
    public nonisolated var defaultTaxable: Bool {
        switch self {
        case .bonus, .signOnBonus, .completionBonus, .referralBonus, .overtime, .holidayPay, .other:
            return true
        case .perDiem, .stipendAdjustment, .travelReimbursement:
            return false
        }
    }
}

/// Represents ad-hoc income outside of regular assignment pay
@Model
public final class Income {
    /// Unique identifier
    public var id: UUID

    /// Type of income
    public var typeRaw: String

    /// Amount received
    public var amount: Decimal

    /// Date received
    public var date: Date

    /// Associated assignment (optional)
    public var assignment: Assignment?

    /// Description or notes
    public var notes: String?

    /// Whether this income is taxable
    public var isTaxable: Bool

    /// Source (agency name, facility, etc.)
    public var source: String?

    /// Tax year for reporting
    public var taxYear: Int

    /// Creation timestamp
    public var createdAt: Date

    // MARK: - Computed Properties

    /// Income type as enum
    public var type: IncomeType {
        get { IncomeType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    /// Formatted amount
    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }

    /// Formatted date
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - Initializer

    public init(
        type: IncomeType,
        amount: Decimal,
        date: Date = Date(),
        source: String? = nil,
        notes: String? = nil,
        isTaxable: Bool? = nil,
        assignment: Assignment? = nil
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.amount = amount
        self.date = date
        self.source = source
        self.notes = notes
        if let isTaxable = isTaxable {
            self.isTaxable = isTaxable
        } else {
            self.isTaxable = type.defaultTaxable
        }
        self.assignment = assignment
        self.taxYear = Calendar.current.component(.year, from: date)
        self.createdAt = Date()
    }
}

