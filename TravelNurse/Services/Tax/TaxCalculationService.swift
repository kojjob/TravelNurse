//
//  TaxCalculationService.swift
//  TravelNurse
//
//  Real tax calculation engine for travel nurses
//  Implements progressive federal tax brackets, state taxes, and self-employment tax
//

import Foundation

// MARK: - Tax Calculation Result

/// Complete breakdown of tax calculation
public struct TaxCalculationResult {
    public let grossIncome: Decimal
    public let deductions: Decimal
    public let taxableIncome: Decimal
    public let federalTax: Decimal
    public let stateTax: Decimal
    public let selfEmploymentTax: Decimal
    public let totalTax: Decimal

    /// Effective tax rate (total tax / gross income)
    public var effectiveTaxRate: Double {
        guard grossIncome > 0 else { return 0 }
        return Double(truncating: (totalTax / grossIncome) as NSNumber)
    }

    /// Take home pay after all taxes
    public var takeHomePay: Decimal {
        grossIncome - totalTax
    }

    /// Marginal tax rate (highest bracket)
    public var marginalTaxRate: Decimal {
        TaxCalculationService.federalMarginalRate(for: taxableIncome)
    }

    public init(
        grossIncome: Decimal,
        deductions: Decimal,
        taxableIncome: Decimal,
        federalTax: Decimal,
        stateTax: Decimal,
        selfEmploymentTax: Decimal,
        totalTax: Decimal
    ) {
        self.grossIncome = grossIncome
        self.deductions = deductions
        self.taxableIncome = taxableIncome
        self.federalTax = federalTax
        self.stateTax = stateTax
        self.selfEmploymentTax = selfEmploymentTax
        self.totalTax = totalTax
    }
}

// MARK: - Quarterly Estimate

/// Quarterly tax payment estimates
public struct QuarterlyEstimate {
    public let q1: Decimal
    public let q1DueDate: Date
    public let q2: Decimal
    public let q2DueDate: Date
    public let q3: Decimal
    public let q3DueDate: Date
    public let q4: Decimal
    public let q4DueDate: Date

    /// Total annual estimate
    public var totalAnnual: Decimal {
        q1 + q2 + q3 + q4
    }
}

// MARK: - Multi-State Result

/// Result for multi-state tax calculations
public struct MultiStateTaxResult {
    public let totalIncome: Decimal
    public let totalDeductions: Decimal
    public let federalTax: Decimal
    public let stateBreakdown: [USState: Decimal]
    public let totalStateTax: Decimal
    public let totalTax: Decimal
}

// MARK: - Tax Calculation Service

/// Service for calculating taxes for travel nurses
public final class TaxCalculationService {

    // MARK: - 2024 Federal Tax Brackets (Single Filer)

    private static let federalBrackets2024: [(threshold: Decimal, rate: Decimal)] = [
        (0, 0.10),           // 10% on income $0 - $11,600
        (11600, 0.12),       // 12% on income $11,600 - $47,150
        (47150, 0.22),       // 22% on income $47,150 - $100,525
        (100525, 0.24),      // 24% on income $100,525 - $191,950
        (191950, 0.32),      // 32% on income $191,950 - $243,725
        (243725, 0.35),      // 35% on income $243,725 - $609,350
        (609350, 0.37)       // 37% on income over $609,350
    ]

    // MARK: - Self-Employment Tax Constants

    private static let seTaxRate: Decimal = 0.153  // 15.3% (12.4% SS + 2.9% Medicare)
    private static let seNetEarningsMultiplier: Decimal = 0.9235  // 92.35%
    private static let seMinimumThreshold: Decimal = 400
    private static let socialSecurityWageBase2024: Decimal = 168600

    // MARK: - State Tax Rates (Simplified - Top Marginal Rates)

    private static let stateTaxRates: [USState: Decimal] = [
        .alabama: 0.05,
        .arizona: 0.0259,
        .arkansas: 0.047,
        .california: 0.1330,
        .colorado: 0.044,
        .connecticut: 0.0699,
        .delaware: 0.066,
        .georgia: 0.0549,
        .hawaii: 0.11,
        .idaho: 0.058,
        .illinois: 0.0495,
        .indiana: 0.0315,
        .iowa: 0.06,
        .kansas: 0.057,
        .kentucky: 0.04,
        .louisiana: 0.0425,
        .maine: 0.0715,
        .maryland: 0.0575,
        .massachusetts: 0.05,
        .michigan: 0.0425,
        .minnesota: 0.0985,
        .mississippi: 0.05,
        .missouri: 0.048,
        .montana: 0.059,
        .nebraska: 0.0664,
        .newJersey: 0.1075,
        .newMexico: 0.059,
        .newYork: 0.109,
        .northCarolina: 0.0475,
        .northDakota: 0.029,
        .ohio: 0.0399,
        .oklahoma: 0.0475,
        .oregon: 0.099,
        .pennsylvania: 0.0307,
        .rhodeIsland: 0.0599,
        .southCarolina: 0.064,
        .tennessee: 0.0,  // No income tax
        .utah: 0.0465,
        .vermont: 0.0875,
        .virginia: 0.0575,
        .westVirginia: 0.0512,
        .wisconsin: 0.0765,
        .districtOfColumbia: 0.1075,
        // No income tax states
        .alaska: 0.0,
        .florida: 0.0,
        .nevada: 0.0,
        .newHampshire: 0.0,  // Only taxes interest/dividends
        .southDakota: 0.0,
        .texas: 0.0,
        .washington: 0.0,
        .wyoming: 0.0
    ]

    // MARK: - Initialization

    public init() {}

    // MARK: - Federal Tax Calculation

    /// Calculate federal income tax using progressive brackets
    public func calculateFederalTax(taxableIncome: Decimal) -> Decimal {
        guard taxableIncome > 0 else { return 0 }

        var tax: Decimal = 0
        var remainingIncome = taxableIncome

        for i in 0..<Self.federalBrackets2024.count {
            let currentBracket = Self.federalBrackets2024[i]
            let nextThreshold: Decimal

            if i + 1 < Self.federalBrackets2024.count {
                nextThreshold = Self.federalBrackets2024[i + 1].threshold
            } else {
                nextThreshold = Decimal.greatestFiniteMagnitude
            }

            let bracketStart = currentBracket.threshold
            let bracketWidth = nextThreshold - bracketStart

            if remainingIncome <= 0 {
                break
            }

            if taxableIncome > bracketStart {
                let incomeInBracket = min(remainingIncome, bracketWidth)
                tax += incomeInBracket * currentBracket.rate
                remainingIncome -= incomeInBracket
            }
        }

        return tax.rounded(0)
    }

    /// Get the marginal tax rate for a given income
    public static func federalMarginalRate(for taxableIncome: Decimal) -> Decimal {
        guard taxableIncome > 0 else { return 0 }

        for i in stride(from: federalBrackets2024.count - 1, through: 0, by: -1) {
            if taxableIncome > federalBrackets2024[i].threshold {
                return federalBrackets2024[i].rate
            }
        }

        return federalBrackets2024[0].rate
    }

    // MARK: - Self-Employment Tax Calculation

    /// Calculate self-employment tax (Social Security + Medicare)
    public func calculateSelfEmploymentTax(netEarnings: Decimal) -> Decimal {
        guard netEarnings >= Self.seMinimumThreshold else { return 0 }

        // Calculate 92.35% of net earnings
        let adjustedEarnings = netEarnings * Self.seNetEarningsMultiplier

        // Social Security tax (12.4%) caps at wage base
        let socialSecurityEarnings = min(adjustedEarnings, Self.socialSecurityWageBase2024)
        let socialSecurityTax = socialSecurityEarnings * Decimal(0.124)

        // Medicare tax (2.9%) has no cap
        let medicareTax = adjustedEarnings * Decimal(0.029)

        // Additional Medicare tax (0.9%) on earnings over $200,000
        var additionalMedicare: Decimal = 0
        if adjustedEarnings > 200000 {
            additionalMedicare = (adjustedEarnings - 200000) * Decimal(0.009)
        }

        return (socialSecurityTax + medicareTax + additionalMedicare).rounded(0)
    }

    // MARK: - State Tax Calculation

    /// Calculate state income tax (simplified flat rate model)
    public func calculateStateTax(taxableIncome: Decimal, state: USState) -> Decimal {
        guard taxableIncome > 0 else { return 0 }

        let rate = Self.stateTaxRates[state] ?? 0

        // Apply simplified progressive adjustment for high-tax states
        var effectiveRate = rate

        // California progressive adjustment
        if state == .california {
            effectiveRate = calculateCaliforniaEffectiveRate(taxableIncome: taxableIncome)
        } else if state == .newYork {
            effectiveRate = calculateNewYorkEffectiveRate(taxableIncome: taxableIncome)
        }

        return (taxableIncome * effectiveRate).rounded(0)
    }

    /// Calculate California effective rate (simplified progressive)
    private func calculateCaliforniaEffectiveRate(taxableIncome: Decimal) -> Decimal {
        // Simplified CA brackets
        if taxableIncome <= 10099 { return 0.01 }
        if taxableIncome <= 23942 { return 0.02 }
        if taxableIncome <= 37788 { return 0.04 }
        if taxableIncome <= 52455 { return 0.06 }
        if taxableIncome <= 66295 { return 0.08 }
        if taxableIncome <= 338639 { return 0.093 }
        if taxableIncome <= 406364 { return 0.103 }
        if taxableIncome <= 677275 { return 0.113 }
        return 0.123
    }

    /// Calculate New York effective rate (simplified progressive)
    private func calculateNewYorkEffectiveRate(taxableIncome: Decimal) -> Decimal {
        // Simplified NY brackets
        if taxableIncome <= 8500 { return 0.04 }
        if taxableIncome <= 11700 { return 0.045 }
        if taxableIncome <= 13900 { return 0.0525 }
        if taxableIncome <= 80650 { return 0.0585 }
        if taxableIncome <= 215400 { return 0.0625 }
        if taxableIncome <= 1077550 { return 0.0685 }
        return 0.103
    }

    // MARK: - Total Tax Calculation

    /// Calculate total tax liability
    public func calculateTotalTax(
        grossIncome: Decimal,
        deductions: Decimal,
        state: USState,
        isSelfEmployed: Bool
    ) -> TaxCalculationResult {
        // Calculate taxable income
        let taxableIncome = max(0, grossIncome - deductions)

        // Calculate federal tax
        let federalTax = calculateFederalTax(taxableIncome: taxableIncome)

        // Calculate state tax
        let stateTax = calculateStateTax(taxableIncome: taxableIncome, state: state)

        // Calculate self-employment tax if applicable
        var selfEmploymentTax: Decimal = 0
        if isSelfEmployed {
            selfEmploymentTax = calculateSelfEmploymentTax(netEarnings: taxableIncome)
        }

        // Total tax
        let totalTax = federalTax + stateTax + selfEmploymentTax

        return TaxCalculationResult(
            grossIncome: grossIncome,
            deductions: deductions,
            taxableIncome: taxableIncome,
            federalTax: federalTax,
            stateTax: stateTax,
            selfEmploymentTax: selfEmploymentTax,
            totalTax: totalTax
        )
    }

    // MARK: - Quarterly Estimates

    /// Calculate quarterly estimated tax payments
    public func calculateQuarterlyEstimate(
        grossIncome: Decimal,
        deductions: Decimal,
        state: USState,
        isSelfEmployed: Bool
    ) -> QuarterlyEstimate {
        let totalTaxResult = calculateTotalTax(
            grossIncome: grossIncome,
            deductions: deductions,
            state: state,
            isSelfEmployed: isSelfEmployed
        )

        let quarterlyAmount = totalTaxResult.totalTax / 4

        let year = Calendar.current.component(.year, from: Date())

        return QuarterlyEstimate(
            q1: quarterlyAmount,
            q1DueDate: makeDate(year: year, month: 4, day: 15),
            q2: quarterlyAmount,
            q2DueDate: makeDate(year: year, month: 6, day: 15),
            q3: quarterlyAmount,
            q3DueDate: makeDate(year: year, month: 9, day: 15),
            q4: quarterlyAmount,
            q4DueDate: makeDate(year: year + 1, month: 1, day: 15)
        )
    }

    // MARK: - Multi-State Tax

    /// Calculate taxes for income earned in multiple states
    public func calculateMultiStateTax(
        stateAllocations: [(state: USState, income: Decimal)],
        totalDeductions: Decimal
    ) -> MultiStateTaxResult {
        let totalIncome = stateAllocations.reduce(Decimal.zero) { $0 + $1.income }

        // Calculate federal tax on total income
        let taxableIncome = max(0, totalIncome - totalDeductions)
        let federalTax = calculateFederalTax(taxableIncome: taxableIncome)

        // Calculate state taxes proportionally
        var stateBreakdown: [USState: Decimal] = [:]
        var totalStateTax: Decimal = 0

        for allocation in stateAllocations {
            // Proportional deductions for this state
            let proportion = totalIncome > 0 ? allocation.income / totalIncome : 0
            let stateDeductions = totalDeductions * proportion
            let stateTaxableIncome = max(0, allocation.income - stateDeductions)

            let stateTax = calculateStateTax(taxableIncome: stateTaxableIncome, state: allocation.state)
            stateBreakdown[allocation.state] = stateTax
            totalStateTax += stateTax
        }

        return MultiStateTaxResult(
            totalIncome: totalIncome,
            totalDeductions: totalDeductions,
            federalTax: federalTax,
            stateBreakdown: stateBreakdown,
            totalStateTax: totalStateTax,
            totalTax: federalTax + totalStateTax
        )
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}

// MARK: - Decimal Extension

extension Decimal {
    /// Round to specified number of decimal places
    func rounded(_ scale: Int) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
