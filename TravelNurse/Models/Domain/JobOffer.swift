//
//  JobOffer.swift
//  TravelNurse
//
//  Model for comparing travel nursing job offers
//

import Foundation

/// Represents a travel nursing job offer for comparison
struct JobOffer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var facilityName: String?
    var location: String?

    // Pay Structure
    var hourlyRate: Decimal
    var hoursPerWeek: Double
    var housingStipend: Decimal
    var mealsStipend: Decimal
    var travelReimbursement: Decimal

    // Optional Pay Components
    var overtimeRate: Decimal?
    var signOnBonus: Decimal?
    var completionBonus: Decimal?
    var referralBonus: Decimal?

    // Contract Details
    var contractWeeks: Int
    var state: USState?

    // MARK: - Computed Properties

    /// Weekly taxable pay (hourly × hours)
    var weeklyTaxable: Decimal {
        hourlyRate * Decimal(hoursPerWeek)
    }

    /// Weekly non-taxable stipends
    var weeklyStipends: Decimal {
        housingStipend + mealsStipend
    }

    /// Weekly gross pay
    var weeklyGross: Decimal {
        weeklyTaxable + weeklyStipends
    }

    /// Daily housing rate
    var dailyHousing: Decimal {
        housingStipend / 7
    }

    /// Daily meals rate
    var dailyMeals: Decimal {
        mealsStipend / 7
    }

    /// Blended hourly rate (includes stipends)
    var blendedHourlyRate: Decimal {
        guard hoursPerWeek > 0 else { return 0 }
        return weeklyGross / Decimal(hoursPerWeek)
    }

    /// Non-taxable percentage of total pay
    var nonTaxablePercentage: Double {
        guard weeklyGross > 0 else { return 0 }
        return Double(truncating: (weeklyStipends / weeklyGross * 100) as NSNumber)
    }

    /// Total contract value (excluding bonuses)
    var totalContractValue: Decimal {
        weeklyGross * Decimal(contractWeeks)
    }

    /// Total bonuses
    var totalBonuses: Decimal {
        (signOnBonus ?? 0) + (completionBonus ?? 0) + (referralBonus ?? 0)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String = "Offer",
        facilityName: String? = nil,
        location: String? = nil,
        hourlyRate: Decimal,
        hoursPerWeek: Double,
        housingStipend: Decimal,
        mealsStipend: Decimal,
        travelReimbursement: Decimal = 0,
        overtimeRate: Decimal? = nil,
        signOnBonus: Decimal? = nil,
        completionBonus: Decimal? = nil,
        referralBonus: Decimal? = nil,
        contractWeeks: Int = 13,
        state: USState? = nil
    ) {
        self.id = id
        self.name = name
        self.facilityName = facilityName
        self.location = location
        self.hourlyRate = hourlyRate
        self.hoursPerWeek = hoursPerWeek
        self.housingStipend = housingStipend
        self.mealsStipend = mealsStipend
        self.travelReimbursement = travelReimbursement
        self.overtimeRate = overtimeRate
        self.signOnBonus = signOnBonus
        self.completionBonus = completionBonus
        self.referralBonus = referralBonus
        self.contractWeeks = contractWeeks
        self.state = state
    }

    // MARK: - Equatable

    static func == (lhs: JobOffer, rhs: JobOffer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Offers

extension JobOffer {
    static let sample1 = JobOffer(
        name: "Stanford Medical",
        facilityName: "Stanford Medical Center",
        location: "Palo Alto, CA",
        hourlyRate: 42,
        hoursPerWeek: 36,
        housingStipend: 2100,
        mealsStipend: 553,
        travelReimbursement: 500,
        completionBonus: 1500,
        contractWeeks: 13,
        state: .california
    )

    static let sample2 = JobOffer(
        name: "Texas Medical",
        facilityName: "Houston Methodist",
        location: "Houston, TX",
        hourlyRate: 38,
        hoursPerWeek: 36,
        housingStipend: 1800,
        mealsStipend: 490,
        signOnBonus: 2000,
        contractWeeks: 13,
        state: .texas
    )

    static let sample3 = JobOffer(
        name: "Florida General",
        facilityName: "Tampa General Hospital",
        location: "Tampa, FL",
        hourlyRate: 35,
        hoursPerWeek: 36,
        housingStipend: 1600,
        mealsStipend: 450,
        contractWeeks: 13,
        state: .florida
    )
}
