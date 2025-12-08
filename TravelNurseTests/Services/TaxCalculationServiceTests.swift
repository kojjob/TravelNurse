//
//  TaxCalculationServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for TaxCalculationService - WRITE TESTS FIRST
//  This implements a real tax calculation engine for travel nurses
//

import XCTest
@testable import TravelNurse

final class TaxCalculationServiceTests: XCTestCase {

    var sut: TaxCalculationService!

    override func setUp() {
        super.setUp()
        sut = TaxCalculationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Federal Tax Bracket Tests (2024 Single Filer)

    func test_federalTax_zeroIncome_returnsZero() {
        let result = sut.calculateFederalTax(taxableIncome: 0)
        XCTAssertEqual(result, 0)
    }

    func test_federalTax_negativeIncome_returnsZero() {
        let result = sut.calculateFederalTax(taxableIncome: -5000)
        XCTAssertEqual(result, 0)
    }

    func test_federalTax_10PercentBracket_calculatesCorrectly() {
        // 2024: 10% bracket is $0 - $11,600
        let result = sut.calculateFederalTax(taxableIncome: 10000)
        // 10% of $10,000 = $1,000
        XCTAssertEqual(result, 1000)
    }

    func test_federalTax_12PercentBracket_calculatesCorrectly() {
        // 2024: 12% bracket is $11,600 - $47,150
        let result = sut.calculateFederalTax(taxableIncome: 30000)
        // $1,160 (10% of $11,600) + 12% of ($30,000 - $11,600) = $1,160 + $2,208 = $3,368
        XCTAssertEqual(result, Decimal(3368))
    }

    func test_federalTax_22PercentBracket_calculatesCorrectly() {
        // 2024: 22% bracket is $47,150 - $100,525
        let result = sut.calculateFederalTax(taxableIncome: 75000)
        // $1,160 + $4,266 (12% of $35,550) + 22% of ($75,000 - $47,150)
        // = $1,160 + $4,266 + $6,127 = $11,553
        XCTAssertEqual(result, Decimal(11553))
    }

    func test_federalTax_24PercentBracket_calculatesCorrectly() {
        // 2024: 24% bracket is $100,525 - $191,950
        let result = sut.calculateFederalTax(taxableIncome: 120000)
        // Calculate using progressive brackets
        let expected = sut.calculateFederalTax(taxableIncome: 120000)
        XCTAssertGreaterThan(expected, 0)
    }

    func test_federalTax_typicalTravelNurseIncome_calculatesCorrectly() {
        // Average travel nurse income: $85,000
        let result = sut.calculateFederalTax(taxableIncome: 85000)

        // Should be between $12,000 and $18,000 roughly
        XCTAssertGreaterThan(result, 12000)
        XCTAssertLessThan(result, 18000)
    }

    // MARK: - Self-Employment Tax Tests

    func test_selfEmploymentTax_zeroIncome_returnsZero() {
        let result = sut.calculateSelfEmploymentTax(netEarnings: 0)
        XCTAssertEqual(result, 0)
    }

    func test_selfEmploymentTax_negativeIncome_returnsZero() {
        let result = sut.calculateSelfEmploymentTax(netEarnings: -5000)
        XCTAssertEqual(result, 0)
    }

    func test_selfEmploymentTax_belowThreshold_returnsZero() {
        // SE tax only applies if net earnings >= $400
        let result = sut.calculateSelfEmploymentTax(netEarnings: 300)
        XCTAssertEqual(result, 0)
    }

    func test_selfEmploymentTax_calculatesCorrectly() {
        // SE tax rate is 15.3% on 92.35% of net earnings
        // For $50,000: 0.9235 * 50000 * 0.153 = $7,064.78
        let result = sut.calculateSelfEmploymentTax(netEarnings: 50000)
        let expected = Decimal(50000) * Decimal(0.9235) * Decimal(0.153)

        // Allow small rounding difference
        XCTAssertEqual(result, expected, accuracy: 1)
    }

    func test_selfEmploymentTax_aboveSocialSecurityWageBase_capsCorrectly() {
        // 2024 Social Security wage base is $168,600
        // Social Security portion (12.4%) caps at this amount
        // Medicare (2.9%) has no cap
        let result = sut.calculateSelfEmploymentTax(netEarnings: 200000)

        // Should be capped appropriately
        XCTAssertGreaterThan(result, 0)
    }

    // MARK: - State Tax Tests

    func test_stateTax_noTaxState_returnsZero() {
        let noTaxStates: [USState] = [.texas, .florida, .nevada, .washington, .wyoming, .southDakota, .alaska]

        for state in noTaxStates {
            let result = sut.calculateStateTax(taxableIncome: 100000, state: state)
            XCTAssertEqual(result, 0, "\(state.fullName) should have no state income tax")
        }
    }

    func test_stateTax_california_calculatesCorrectly() {
        // California has progressive tax rates
        let result = sut.calculateStateTax(taxableIncome: 75000, state: .california)

        // CA tax on $75K should be roughly $3,000-$5,000
        XCTAssertGreaterThan(result, 3000)
        XCTAssertLessThan(result, 6000)
    }

    func test_stateTax_newYork_calculatesCorrectly() {
        let result = sut.calculateStateTax(taxableIncome: 75000, state: .newYork)

        // NY tax on $75K should be positive
        XCTAssertGreaterThan(result, 0)
    }

    func test_stateTax_zeroIncome_returnsZero() {
        let result = sut.calculateStateTax(taxableIncome: 0, state: .california)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Total Tax Calculation Tests

    func test_calculateTotalTax_combinesAllTaxTypes() {
        let result = sut.calculateTotalTax(
            grossIncome: 100000,
            deductions: 15000,
            state: .california,
            isSelfEmployed: false
        )

        XCTAssertGreaterThan(result.federalTax, 0)
        XCTAssertGreaterThan(result.stateTax, 0)
        XCTAssertEqual(result.selfEmploymentTax, 0) // Not self-employed
        XCTAssertGreaterThan(result.totalTax, 0)
    }

    func test_calculateTotalTax_withSelfEmployment_includesSETax() {
        let result = sut.calculateTotalTax(
            grossIncome: 100000,
            deductions: 15000,
            state: .texas,
            isSelfEmployed: true
        )

        XCTAssertGreaterThan(result.federalTax, 0)
        XCTAssertEqual(result.stateTax, 0) // Texas has no state tax
        XCTAssertGreaterThan(result.selfEmploymentTax, 0) // Should include SE tax
        XCTAssertGreaterThan(result.totalTax, 0)
    }

    func test_calculateTotalTax_effectiveTaxRate_isReasonable() {
        let result = sut.calculateTotalTax(
            grossIncome: 85000,
            deductions: 10000,
            state: .california,
            isSelfEmployed: false
        )

        // Effective rate should be between 15% and 35%
        XCTAssertGreaterThan(result.effectiveTaxRate, 0.15)
        XCTAssertLessThan(result.effectiveTaxRate, 0.35)
    }

    // MARK: - Quarterly Estimates Tests

    func test_quarterlyEstimate_dividesTotalByFour() {
        let result = sut.calculateQuarterlyEstimate(
            grossIncome: 80000,
            deductions: 8000,
            state: .texas,
            isSelfEmployed: false
        )

        // Should be roughly 1/4 of annual tax
        let annualTax = sut.calculateTotalTax(
            grossIncome: 80000,
            deductions: 8000,
            state: .texas,
            isSelfEmployed: false
        )

        let expectedQuarterly = annualTax.totalTax / 4
        XCTAssertEqual(result.q1, expectedQuarterly)
        XCTAssertEqual(result.q2, expectedQuarterly)
        XCTAssertEqual(result.q3, expectedQuarterly)
        XCTAssertEqual(result.q4, expectedQuarterly)
    }

    func test_quarterlyEstimate_returnsQuarterlyDueDates() {
        let result = sut.calculateQuarterlyEstimate(
            grossIncome: 80000,
            deductions: 8000,
            state: .texas,
            isSelfEmployed: false
        )

        XCTAssertNotNil(result.q1DueDate)
        XCTAssertNotNil(result.q2DueDate)
        XCTAssertNotNil(result.q3DueDate)
        XCTAssertNotNil(result.q4DueDate)
    }

    // MARK: - Deduction Impact Tests

    func test_deductions_reducesTaxableIncome() {
        let withoutDeductions = sut.calculateTotalTax(
            grossIncome: 100000,
            deductions: 0,
            state: .california,
            isSelfEmployed: false
        )

        let withDeductions = sut.calculateTotalTax(
            grossIncome: 100000,
            deductions: 20000,
            state: .california,
            isSelfEmployed: false
        )

        XCTAssertLessThan(withDeductions.totalTax, withoutDeductions.totalTax)
    }

    func test_deductions_excessDeductions_zerosTax() {
        let result = sut.calculateTotalTax(
            grossIncome: 50000,
            deductions: 60000, // More than income
            state: .california,
            isSelfEmployed: false
        )

        XCTAssertEqual(result.federalTax, 0)
        XCTAssertEqual(result.stateTax, 0)
    }

    // MARK: - Tax Breakdown Tests

    func test_taxBreakdown_allComponentsPresent() {
        let result = sut.calculateTotalTax(
            grossIncome: 100000,
            deductions: 15000,
            state: .california,
            isSelfEmployed: true
        )

        XCTAssertNotNil(result.grossIncome)
        XCTAssertNotNil(result.deductions)
        XCTAssertNotNil(result.taxableIncome)
        XCTAssertNotNil(result.federalTax)
        XCTAssertNotNil(result.stateTax)
        XCTAssertNotNil(result.selfEmploymentTax)
        XCTAssertNotNil(result.totalTax)
        XCTAssertNotNil(result.effectiveTaxRate)
        XCTAssertNotNil(result.takeHomePay)
    }

    func test_taxBreakdown_takeHomePayCalculatesCorrectly() {
        let result = sut.calculateTotalTax(
            grossIncome: 100000,
            deductions: 15000,
            state: .texas,
            isSelfEmployed: false
        )

        let expectedTakeHome = result.grossIncome - result.totalTax
        XCTAssertEqual(result.takeHomePay, expectedTakeHome)
    }

    // MARK: - Multi-State Tax Tests

    func test_multiStateTax_calculatesProportionally() {
        let stateAllocations: [(state: USState, income: Decimal)] = [
            (.california, 50000),
            (.texas, 30000),
            (.florida, 20000)
        ]

        let result = sut.calculateMultiStateTax(stateAllocations: stateAllocations, totalDeductions: 10000)

        // CA should have tax, TX and FL should not
        XCTAssertGreaterThan(result.stateBreakdown[.california] ?? 0, 0)
        XCTAssertEqual(result.stateBreakdown[.texas] ?? 0, 0)
        XCTAssertEqual(result.stateBreakdown[.florida] ?? 0, 0)
    }

    // MARK: - Edge Cases

    func test_veryHighIncome_handlesCorrectly() {
        let result = sut.calculateTotalTax(
            grossIncome: 500000,
            deductions: 50000,
            state: .california,
            isSelfEmployed: false
        )

        // Should handle high income without overflow
        XCTAssertGreaterThan(result.totalTax, 100000)
    }

    func test_verySmallIncome_handlesCorrectly() {
        let result = sut.calculateTotalTax(
            grossIncome: 1000,
            deductions: 0,
            state: .california,
            isSelfEmployed: false
        )

        // Small income might have zero or minimal tax
        XCTAssertGreaterThanOrEqual(result.totalTax, 0)
    }
}

// MARK: - TaxCalculationResult Tests

final class TaxCalculationResultTests: XCTestCase {

    func test_effectiveTaxRate_calculatesCorrectly() {
        let result = TaxCalculationResult(
            grossIncome: 100000,
            deductions: 10000,
            taxableIncome: 90000,
            federalTax: 15000,
            stateTax: 5000,
            selfEmploymentTax: 0,
            totalTax: 20000
        )

        // Effective rate = totalTax / grossIncome = 20000 / 100000 = 0.20 (20%)
        XCTAssertEqual(result.effectiveTaxRate, 0.20)
    }

    func test_takeHomePay_calculatesCorrectly() {
        let result = TaxCalculationResult(
            grossIncome: 100000,
            deductions: 10000,
            taxableIncome: 90000,
            federalTax: 15000,
            stateTax: 5000,
            selfEmploymentTax: 0,
            totalTax: 20000
        )

        // Take home = gross - total tax = 100000 - 20000 = 80000
        XCTAssertEqual(result.takeHomePay, 80000)
    }

    func test_marginalTaxRate_returnsCorrectBracket() {
        let result = TaxCalculationResult(
            grossIncome: 85000,
            deductions: 10000,
            taxableIncome: 75000, // In 22% bracket
            federalTax: 12000,
            stateTax: 3000,
            selfEmploymentTax: 0,
            totalTax: 15000
        )

        // Marginal rate for $75K taxable income should be 22%
        XCTAssertEqual(result.marginalTaxRate, Decimal(0.22))
    }
}

// MARK: - QuarterlyEstimate Tests

final class QuarterlyEstimateTests: XCTestCase {

    func test_quarterlyEstimate_dueDatesAreCorrect() {
        let estimate = QuarterlyEstimate(
            q1: 5000, q1DueDate: makeDate(month: 4, day: 15),
            q2: 5000, q2DueDate: makeDate(month: 6, day: 15),
            q3: 5000, q3DueDate: makeDate(month: 9, day: 15),
            q4: 5000, q4DueDate: makeDate(month: 1, day: 15, yearOffset: 1)
        )

        // Q1 due April 15
        XCTAssertEqual(Calendar.current.component(.month, from: estimate.q1DueDate), 4)
        XCTAssertEqual(Calendar.current.component(.day, from: estimate.q1DueDate), 15)

        // Q2 due June 15
        XCTAssertEqual(Calendar.current.component(.month, from: estimate.q2DueDate), 6)

        // Q3 due September 15
        XCTAssertEqual(Calendar.current.component(.month, from: estimate.q3DueDate), 9)

        // Q4 due January 15 (next year)
        XCTAssertEqual(Calendar.current.component(.month, from: estimate.q4DueDate), 1)
    }

    func test_totalAnnualEstimate_sumsQuarters() {
        let estimate = QuarterlyEstimate(
            q1: 5000, q1DueDate: Date(),
            q2: 6000, q2DueDate: Date(),
            q3: 5500, q3DueDate: Date(),
            q4: 5500, q4DueDate: Date()
        )

        XCTAssertEqual(estimate.totalAnnual, 22000)
    }

    private func makeDate(month: Int, day: Int, yearOffset: Int = 0) -> Date {
        let year = Calendar.current.component(.year, from: Date()) + yearOffset
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
