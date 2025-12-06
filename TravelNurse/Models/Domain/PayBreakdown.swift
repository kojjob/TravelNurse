//
//  PayBreakdown.swift
//  TravelNurse
//
//  Pay breakdown model for assignment compensation
//

import Foundation
import SwiftData

/// Detailed pay breakdown for a travel nursing assignment
/// Travel nurse pay typically includes taxable hourly wage + non-taxable stipends
@Model
public final class PayBreakdown {
    /// Unique identifier
    public var id: UUID

    /// Taxable hourly rate
    public var hourlyRate: Decimal

    /// Weekly housing stipend (non-taxable if duplicating expenses)
    public var housingStipend: Decimal

    /// Weekly meals & incidentals stipend (M&IE, non-taxable)
    public var mealsStipend: Decimal

    /// Travel reimbursement (one-time or per-trip)
    public var travelReimbursement: Decimal

    /// Overtime hourly rate (typically 1.5x)
    public var overtimeRate: Decimal?

    /// Holiday pay rate
    public var holidayRate: Decimal?

    /// On-call hourly rate
    public var onCallRate: Decimal?

    /// Call-back pay rate
    public var callBackRate: Decimal?

    /// Completion bonus (end of contract)
    public var completionBonus: Decimal?

    /// Sign-on bonus
    public var signOnBonus: Decimal?

    /// Referral bonus
    public var referralBonus: Decimal?

    /// Guaranteed weekly hours for pay calculation
    public var guaranteedHours: Double

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Weekly taxable pay (hourly rate × hours)
    public var weeklyTaxable: Decimal {
        hourlyRate * Decimal(guaranteedHours)
    }

    /// Weekly non-taxable stipends (housing + M&IE)
    public var weeklyStipends: Decimal {
        housingStipend + mealsStipend
    }

    /// Total weekly gross pay
    public var weeklyGross: Decimal {
        weeklyTaxable + weeklyStipends
    }

    /// Estimated annual gross (52 weeks)
    public var annualGross: Decimal {
        weeklyGross * 52
    }

    /// Blended hourly rate (total weekly ÷ hours)
    public var blendedHourlyRate: Decimal {
        guard guaranteedHours > 0 else { return 0 }
        return weeklyGross / Decimal(guaranteedHours)
    }

    /// Percentage of pay that is non-taxable
    public var nonTaxablePercentage: Double {
        guard weeklyGross > 0 else { return 0 }
        return Double(truncating: (weeklyStipends / weeklyGross * 100) as NSNumber)
    }

    /// Total one-time bonuses
    public var totalBonuses: Decimal {
        (completionBonus ?? 0) + (signOnBonus ?? 0) + (referralBonus ?? 0)
    }

    // MARK: - Initializer

    public init(
        hourlyRate: Decimal,
        housingStipend: Decimal = 0,
        mealsStipend: Decimal = 0,
        travelReimbursement: Decimal = 0,
        guaranteedHours: Double = 36
    ) {
        self.id = UUID()
        self.hourlyRate = hourlyRate
        self.housingStipend = housingStipend
        self.mealsStipend = mealsStipend
        self.travelReimbursement = travelReimbursement
        self.guaranteedHours = guaranteedHours
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Formatting Helpers

extension PayBreakdown {
    /// Formatted weekly gross pay
    public var weeklyGrossFormatted: String {
        formatCurrency(weeklyGross)
    }

    /// Formatted hourly rate
    public var hourlyRateFormatted: String {
        formatCurrency(hourlyRate) + "/hr"
    }

    /// Formatted blended rate
    public var blendedRateFormatted: String {
        formatCurrency(blendedHourlyRate) + "/hr blended"
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSNumber) ?? "$0.00"
    }
}

// MARK: - GSA Per Diem Reference

extension PayBreakdown {
    /// Note: GSA per diem rates vary by location and should be validated
    /// against official GSA rates for the assignment location
    public static let defaultMealsPerDiem: Decimal = 79 // 2024 default M&IE
    public static let defaultLodgingPerDiem: Decimal = 107 // 2024 default lodging

    /// Check if stipends are within GSA limits
    public func stipendsWithinGSALimits(
        gsaLodging: Decimal,
        gsaMeals: Decimal
    ) -> Bool {
        let dailyHousing = housingStipend / 7
        let dailyMeals = mealsStipend / 7
        return dailyHousing <= gsaLodging && dailyMeals <= gsaMeals
    }
}
