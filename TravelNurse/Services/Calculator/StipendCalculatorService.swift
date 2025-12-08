//
//  StipendCalculatorService.swift
//  TravelNurse
//
//  Service for calculating and comparing travel nurse compensation
//

import Foundation

// MARK: - GSA Compliance Result

/// Result of GSA per diem compliance check
struct GSAComplianceResult {
    let isCompliant: Bool
    let housingWithinLimit: Bool
    let mealsWithinLimit: Bool
    let dailyHousing: Decimal
    let dailyMeals: Decimal
    let gsaDailyLodging: Decimal
    let gsaDailyMeals: Decimal

    var housingExcess: Decimal {
        max(0, dailyHousing - gsaDailyLodging)
    }

    var mealsExcess: Decimal {
        max(0, dailyMeals - gsaDailyMeals)
    }
}

// MARK: - Offer Comparison Result

/// Detailed comparison result for a job offer
struct OfferComparisonResult: Identifiable {
    let id: UUID
    let offer: JobOffer
    let weeklyGross: Decimal
    let weeklyTakeHome: Decimal
    let annualGross: Decimal
    let annualTakeHome: Decimal
    let blendedRate: Decimal
    let nonTaxablePercentage: Double
    let effectiveTaxRate: Double
    let rank: Int

    init(offer: JobOffer, weeklyGross: Decimal, weeklyTakeHome: Decimal, annualGross: Decimal, annualTakeHome: Decimal, blendedRate: Decimal, nonTaxablePercentage: Double, effectiveTaxRate: Double, rank: Int = 0) {
        self.id = offer.id
        self.offer = offer
        self.weeklyGross = weeklyGross
        self.weeklyTakeHome = weeklyTakeHome
        self.annualGross = annualGross
        self.annualTakeHome = annualTakeHome
        self.blendedRate = blendedRate
        self.nonTaxablePercentage = nonTaxablePercentage
        self.effectiveTaxRate = effectiveTaxRate
        self.rank = rank
    }
}

// MARK: - Stipend Calculator Service

/// Service for calculating travel nurse pay and comparing job offers
final class StipendCalculatorService {

    // MARK: - Constants

    /// 2024 IRS mileage rate
    static let mileageRate: Decimal = 0.67

    /// Default federal tax brackets (2024, single filer)
    static let federalTaxBrackets: [(threshold: Decimal, rate: Decimal)] = [
        (11600, 0.10),
        (47150, 0.12),
        (100525, 0.22),
        (191950, 0.24),
        (243725, 0.32),
        (609350, 0.35),
        (Decimal.greatestFiniteMagnitude, 0.37)
    ]

    /// Default GSA per diem rates (2024 national average)
    static let defaultGSALodging: Decimal = 107
    static let defaultGSAMeals: Decimal = 79

    // MARK: - Weekly Calculations

    /// Calculate weekly taxable pay
    func calculateWeeklyTaxable(hourlyRate: Decimal, hoursPerWeek: Double) -> Decimal {
        hourlyRate * Decimal(hoursPerWeek)
    }

    /// Calculate weekly stipends total
    func calculateWeeklyStipends(housing: Decimal, meals: Decimal) -> Decimal {
        housing + meals
    }

    /// Calculate weekly gross pay for an offer
    func calculateWeeklyGross(offer: JobOffer) -> Decimal {
        offer.weeklyTaxable + offer.weeklyStipends
    }

    /// Calculate weekly take-home pay after taxes
    func calculateWeeklyTakeHome(
        offer: JobOffer,
        federalTaxRate: Decimal,
        stateTaxRate: Decimal
    ) -> Decimal {
        let taxable = offer.weeklyTaxable
        let totalTaxRate = federalTaxRate + stateTaxRate
        let taxes = taxable * totalTaxRate
        let afterTaxTaxable = taxable - taxes

        return afterTaxTaxable + offer.weeklyStipends
    }

    /// Calculate weekly pay including overtime
    func calculateWeeklyWithOvertime(offer: JobOffer, overtimeHours: Double) -> Decimal {
        var total = offer.weeklyGross

        if let otRate = offer.overtimeRate, overtimeHours > 0 {
            total += otRate * Decimal(overtimeHours)
        }

        return total
    }

    // MARK: - Rate Calculations

    /// Calculate blended hourly rate (gross / hours)
    func calculateBlendedRate(offer: JobOffer) -> Decimal {
        guard offer.hoursPerWeek > 0 else { return 0 }
        let gross = calculateWeeklyGross(offer: offer)
        return gross / Decimal(offer.hoursPerWeek)
    }

    /// Calculate non-taxable percentage
    func calculateNonTaxablePercentage(offer: JobOffer) -> Double {
        let gross = calculateWeeklyGross(offer: offer)
        guard gross > 0 else { return 0 }
        let percentage = (offer.weeklyStipends / gross) * 100
        return Double(truncating: percentage as NSNumber)
    }

    // MARK: - Annual Projections

    /// Calculate annual gross pay
    func calculateAnnualGross(offer: JobOffer, weeksWorked: Int) -> Decimal {
        calculateWeeklyGross(offer: offer) * Decimal(weeksWorked)
    }

    /// Calculate annual take-home pay
    func calculateAnnualTakeHome(
        offer: JobOffer,
        weeksWorked: Int,
        federalTaxRate: Decimal,
        stateTaxRate: Decimal
    ) -> Decimal {
        let weeklyTakeHome = calculateWeeklyTakeHome(
            offer: offer,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate
        )
        return weeklyTakeHome * Decimal(weeksWorked)
    }

    // MARK: - GSA Compliance

    /// Check if stipends are within GSA per diem limits
    func checkGSACompliance(
        offer: JobOffer,
        gsaDailyLodging: Decimal,
        gsaDailyMeals: Decimal
    ) -> GSAComplianceResult {
        let dailyHousing = offer.dailyHousing
        let dailyMeals = offer.dailyMeals

        let housingOK = dailyHousing <= gsaDailyLodging
        let mealsOK = dailyMeals <= gsaDailyMeals

        return GSAComplianceResult(
            isCompliant: housingOK && mealsOK,
            housingWithinLimit: housingOK,
            mealsWithinLimit: mealsOK,
            dailyHousing: dailyHousing,
            dailyMeals: dailyMeals,
            gsaDailyLodging: gsaDailyLodging,
            gsaDailyMeals: gsaDailyMeals
        )
    }

    // MARK: - Tax Bracket Estimation

    /// Estimate federal tax bracket based on annual taxable income
    func estimateFederalTaxBracket(annualIncome: Decimal) -> Decimal {
        for bracket in Self.federalTaxBrackets {
            if annualIncome <= bracket.threshold {
                return bracket.rate
            }
        }
        return 0.37 // Top bracket
    }

    /// Get state tax rate (simplified)
    func getStateTaxRate(for state: USState?) -> Decimal {
        guard let state = state else { return 0 }

        // States with no income tax
        let noIncomeTaxStates: Set<USState> = [.texas, .florida, .washington, .nevada, .wyoming, .southDakota, .alaska]

        if noIncomeTaxStates.contains(state) {
            return 0
        }

        // Simplified state tax rates (average rates)
        switch state {
        case .california: return 0.0930
        case .newYork: return 0.0685
        case .newJersey: return 0.0637
        case .oregon: return 0.0900
        case .minnesota: return 0.0785
        case .massachusetts: return 0.0500
        case .hawaii: return 0.0825
        case .connecticut: return 0.0699
        default: return 0.05 // Default average
        }
    }

    // MARK: - Offer Comparison

    /// Compare multiple job offers
    func compareOffers(
        _ offers: [JobOffer],
        federalTaxRate: Decimal,
        stateTaxRate: Decimal,
        weeksWorked: Int = 48
    ) -> [OfferComparisonResult] {
        var results: [OfferComparisonResult] = []

        for offer in offers {
            let weeklyGross = calculateWeeklyGross(offer: offer)
            let weeklyTakeHome = calculateWeeklyTakeHome(
                offer: offer,
                federalTaxRate: federalTaxRate,
                stateTaxRate: stateTaxRate
            )
            let annualGross = calculateAnnualGross(offer: offer, weeksWorked: weeksWorked)
            let annualTakeHome = calculateAnnualTakeHome(
                offer: offer,
                weeksWorked: weeksWorked,
                federalTaxRate: federalTaxRate,
                stateTaxRate: stateTaxRate
            )
            let blendedRate = calculateBlendedRate(offer: offer)
            let nonTaxablePercentage = calculateNonTaxablePercentage(offer: offer)

            // Calculate effective tax rate
            let totalTaxes = (weeklyGross - weeklyTakeHome) * Decimal(weeksWorked)
            let effectiveTaxRate = annualGross > 0 ? Double(truncating: (totalTaxes / annualGross * 100) as NSNumber) : 0

            results.append(OfferComparisonResult(
                offer: offer,
                weeklyGross: weeklyGross,
                weeklyTakeHome: weeklyTakeHome,
                annualGross: annualGross,
                annualTakeHome: annualTakeHome,
                blendedRate: blendedRate,
                nonTaxablePercentage: nonTaxablePercentage,
                effectiveTaxRate: effectiveTaxRate
            ))
        }

        // Sort by weekly take-home (highest first) and assign ranks
        results.sort { $0.weeklyTakeHome > $1.weeklyTakeHome }

        return results.enumerated().map { index, result in
            OfferComparisonResult(
                offer: result.offer,
                weeklyGross: result.weeklyGross,
                weeklyTakeHome: result.weeklyTakeHome,
                annualGross: result.annualGross,
                annualTakeHome: result.annualTakeHome,
                blendedRate: result.blendedRate,
                nonTaxablePercentage: result.nonTaxablePercentage,
                effectiveTaxRate: result.effectiveTaxRate,
                rank: index + 1
            )
        }
    }

    /// Find the best offer based on take-home pay
    func findBestOffer(
        _ offers: [JobOffer],
        federalTaxRate: Decimal,
        stateTaxRate: Decimal
    ) -> JobOffer? {
        let comparisons = compareOffers(
            offers,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate
        )
        return comparisons.first?.offer
    }

    // MARK: - Scenario Analysis

    /// Calculate the tax savings from stipends vs all-taxable pay
    func calculateStipendTaxSavings(
        offer: JobOffer,
        federalTaxRate: Decimal,
        stateTaxRate: Decimal,
        weeksWorked: Int = 48
    ) -> Decimal {
        let totalTaxRate = federalTaxRate + stateTaxRate

        // Scenario 1: Current (with stipends)
        let currentTakeHome = calculateAnnualTakeHome(
            offer: offer,
            weeksWorked: weeksWorked,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate
        )

        // Scenario 2: All taxable (same gross, no stipends)
        let allTaxableGross = calculateAnnualGross(offer: offer, weeksWorked: weeksWorked)
        let allTaxableTakeHome = allTaxableGross * (1 - totalTaxRate)

        return currentTakeHome - allTaxableTakeHome
    }
}
