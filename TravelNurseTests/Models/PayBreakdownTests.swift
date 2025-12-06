//
//  PayBreakdownTests.swift
//  TravelNurseTests
//
//  Unit tests for PayBreakdown model
//

import Testing
import Foundation
@testable import TravelNurse

@Suite("PayBreakdown Tests")
struct PayBreakdownTests {

    // MARK: - Initialization Tests

    @Test("PayBreakdown initializes with correct values")
    func testInitialization() {
        let pay = PayBreakdown(
            hourlyRate: 35.00,
            housingStipend: 1500,
            mealsStipend: 400,
            travelReimbursement: 500,
            guaranteedHours: 36
        )

        #expect(pay.hourlyRate == 35.00)
        #expect(pay.housingStipend == 1500)
        #expect(pay.mealsStipend == 400)
        #expect(pay.travelReimbursement == 500)
        #expect(pay.guaranteedHours == 36)
    }

    // MARK: - Weekly Calculations Tests

    @Test("Weekly taxable calculation is correct")
    func testWeeklyTaxable() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 0,
            mealsStipend: 0,
            guaranteedHours: 36
        )

        // 30 * 36 = 1080
        #expect(pay.weeklyTaxable == 1080)
    }

    @Test("Weekly stipends calculation is correct")
    func testWeeklyStipends() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 1500,
            mealsStipend: 400,
            guaranteedHours: 36
        )

        // 1500 + 400 = 1900
        #expect(pay.weeklyStipends == 1900)
    }

    @Test("Weekly gross calculation is correct")
    func testWeeklyGross() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 1500,
            mealsStipend: 400,
            guaranteedHours: 36
        )

        // (30 * 36) + 1500 + 400 = 1080 + 1900 = 2980
        #expect(pay.weeklyGross == 2980)
    }

    // MARK: - Blended Rate Tests

    @Test("Blended hourly rate calculation is correct")
    func testBlendedHourlyRate() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 1500,
            mealsStipend: 400,
            guaranteedHours: 36
        )

        // 2980 / 36 = 82.78 (approximately)
        let blended = pay.blendedHourlyRate
        #expect(blended > 82 && blended < 83)
    }

    @Test("Blended rate is zero when hours are zero")
    func testBlendedRateZeroHours() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            guaranteedHours: 0
        )

        #expect(pay.blendedHourlyRate == 0)
    }

    // MARK: - Non-Taxable Percentage Tests

    @Test("Non-taxable percentage calculation is correct")
    func testNonTaxablePercentage() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 1500,
            mealsStipend: 400,
            guaranteedHours: 36
        )

        // Stipends: 1900, Gross: 2980
        // 1900 / 2980 * 100 = 63.76%
        let percentage = pay.nonTaxablePercentage
        #expect(percentage > 63 && percentage < 64)
    }

    // MARK: - Annual Calculation Tests

    @Test("Annual gross calculation is correct")
    func testAnnualGross() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 1500,
            mealsStipend: 400,
            guaranteedHours: 36
        )

        // 2980 * 52 = 154,960
        #expect(pay.annualGross == 154960)
    }

    // MARK: - Bonus Calculation Tests

    @Test("Total bonuses calculation is correct")
    func testTotalBonuses() {
        let pay = PayBreakdown(hourlyRate: 30.00, guaranteedHours: 36)
        pay.completionBonus = 1000
        pay.signOnBonus = 500
        pay.referralBonus = 250

        #expect(pay.totalBonuses == 1750)
    }

    @Test("Total bonuses is zero when no bonuses set")
    func testTotalBonusesNil() {
        let pay = PayBreakdown(hourlyRate: 30.00, guaranteedHours: 36)

        #expect(pay.totalBonuses == 0)
    }

    // MARK: - Formatting Tests

    @Test("Formatted values include currency symbol")
    func testFormattedValues() {
        let pay = PayBreakdown(
            hourlyRate: 35.00,
            housingStipend: 1500,
            mealsStipend: 400,
            guaranteedHours: 36
        )

        #expect(pay.weeklyGrossFormatted.contains("$"))
        #expect(pay.hourlyRateFormatted.contains("/hr"))
        #expect(pay.blendedRateFormatted.contains("blended"))
    }

    // MARK: - GSA Limits Tests

    @Test("Stipends within GSA limits check works")
    func testStipendsWithinGSALimits() {
        let pay = PayBreakdown(
            hourlyRate: 30.00,
            housingStipend: 700, // 100/day
            mealsStipend: 490,  // 70/day
            guaranteedHours: 36
        )

        // Daily housing: 100, Daily meals: 70
        #expect(pay.stipendsWithinGSALimits(gsaLodging: 150, gsaMeals: 79) == true)
        #expect(pay.stipendsWithinGSALimits(gsaLodging: 80, gsaMeals: 79) == false)
    }
}
