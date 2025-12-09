//
//  StipendCalculatorServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for StipendCalculatorService
//

import XCTest
@testable import TravelNurse

final class StipendCalculatorServiceTests: XCTestCase {

    var sut: StipendCalculatorService!

    override func setUp() {
        super.setUp()
        sut = StipendCalculatorService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Weekly Pay Calculation Tests

    func testCalculateWeeklyTaxablePay() {
        // Given
        let hourlyRate: Decimal = 35
        let hoursPerWeek: Double = 36

        // When
        let result = sut.calculateWeeklyTaxable(hourlyRate: hourlyRate, hoursPerWeek: hoursPerWeek)

        // Then
        XCTAssertEqual(result, 1260) // 35 * 36 = 1260
    }

    func testCalculateWeeklyStipends() {
        // Given
        let housingStipend: Decimal = 2100
        let mealsStipend: Decimal = 553

        // When
        let result = sut.calculateWeeklyStipends(housing: housingStipend, meals: mealsStipend)

        // Then
        XCTAssertEqual(result, 2653)
    }

    func testCalculateWeeklyGross() {
        // Given
        let offer = JobOffer(
            hourlyRate: 35,
            hoursPerWeek: 36,
            housingStipend: 2100,
            mealsStipend: 553
        )

        // When
        let result = sut.calculateWeeklyGross(offer: offer)

        // Then
        XCTAssertEqual(result, 3913) // 1260 + 2653
    }

    // MARK: - Take Home Pay Tests

    func testCalculateTakeHomePay() {
        // Given
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2000,
            mealsStipend: 500
        )
        let federalTaxRate: Decimal = 0.22
        let stateTaxRate: Decimal = 0.05

        // When
        let result = sut.calculateWeeklyTakeHome(
            offer: offer,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate
        )

        // Then
        // Weekly taxable: 40 * 36 = 1440
        // Taxes: 1440 * (0.22 + 0.05) = 1440 * 0.27 = 388.80
        // After tax taxable: 1440 - 388.80 = 1051.20
        // Total take home: 1051.20 + 2500 (stipends) = 3551.20
        XCTAssertEqual(result, Decimal(string: "3551.2")!)
    }

    func testCalculateTakeHomePayNoStateTax() {
        // Given - Texas (no state income tax)
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2000,
            mealsStipend: 500
        )
        let federalTaxRate: Decimal = 0.22
        let stateTaxRate: Decimal = 0.0

        // When
        let result = sut.calculateWeeklyTakeHome(
            offer: offer,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate
        )

        // Then
        // Weekly taxable: 1440
        // Taxes: 1440 * 0.22 = 316.80
        // After tax: 1440 - 316.80 = 1123.20
        // Total: 1123.20 + 2500 = 3623.20
        XCTAssertEqual(result, Decimal(string: "3623.2")!)
    }

    // MARK: - Blended Rate Tests

    func testCalculateBlendedHourlyRate() {
        // Given
        let offer = JobOffer(
            hourlyRate: 35,
            hoursPerWeek: 36,
            housingStipend: 2100,
            mealsStipend: 553
        )

        // When
        let result = sut.calculateBlendedRate(offer: offer)

        // Then
        // Weekly gross: 3913
        // Blended: 3913 / 36 = 108.69
        Decimal.assertEqual(result, Decimal(string: "108.69")!, accuracy: Decimal(string: "0.01")!)
    }

    func testCalculateBlendedRateZeroHours() {
        // Given
        let offer = JobOffer(
            hourlyRate: 35,
            hoursPerWeek: 0,
            housingStipend: 2100,
            mealsStipend: 553
        )

        // When
        let result = sut.calculateBlendedRate(offer: offer)

        // Then
        XCTAssertEqual(result, 0)
    }

    // MARK: - Non-Taxable Percentage Tests

    func testCalculateNonTaxablePercentage() {
        // Given
        let offer = JobOffer(
            hourlyRate: 35,
            hoursPerWeek: 36,
            housingStipend: 2100,
            mealsStipend: 553
        )

        // When
        let result = sut.calculateNonTaxablePercentage(offer: offer)

        // Then
        // Stipends: 2653, Gross: 3913
        // Percentage: 2653 / 3913 = 67.8%
        XCTAssertEqual(result, 67.8, accuracy: 0.1)
    }

    // MARK: - Annual Projections Tests

    func testCalculateAnnualGross() {
        // Given
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2000,
            mealsStipend: 500
        )
        let weeksWorked = 48

        // When
        let result = sut.calculateAnnualGross(offer: offer, weeksWorked: weeksWorked)

        // Then
        // Weekly: 1440 + 2500 = 3940
        // Annual: 3940 * 48 = 189,120
        XCTAssertEqual(result, 189120)
    }

    func testCalculateAnnualTakeHome() {
        // Given
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2000,
            mealsStipend: 500
        )
        let weeksWorked = 48
        let federalTaxRate: Decimal = 0.22
        let stateTaxRate: Decimal = 0.0

        // When
        let result = sut.calculateAnnualTakeHome(
            offer: offer,
            weeksWorked: weeksWorked,
            federalTaxRate: federalTaxRate,
            stateTaxRate: stateTaxRate
        )

        // Then
        // Weekly take home: 3623.20
        // Annual: 3623.20 * 48 = 173,913.60
        XCTAssertEqual(result, Decimal(string: "173913.6")!)
    }

    // MARK: - GSA Per Diem Tests

    func testCheckGSACompliance_WithinLimits() {
        // Given
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 700, // $100/day
            mealsStipend: 490    // $70/day
        )
        let gsaLodging: Decimal = 120 // per day
        let gsaMeals: Decimal = 79    // per day

        // When
        let result = sut.checkGSACompliance(
            offer: offer,
            gsaDailyLodging: gsaLodging,
            gsaDailyMeals: gsaMeals
        )

        // Then
        XCTAssertTrue(result.isCompliant)
        XCTAssertTrue(result.housingWithinLimit)
        XCTAssertTrue(result.mealsWithinLimit)
    }

    func testCheckGSACompliance_ExceedsLimits() {
        // Given
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2100, // $300/day - exceeds!
            mealsStipend: 700     // $100/day - exceeds!
        )
        let gsaLodging: Decimal = 150
        let gsaMeals: Decimal = 79

        // When
        let result = sut.checkGSACompliance(
            offer: offer,
            gsaDailyLodging: gsaLodging,
            gsaDailyMeals: gsaMeals
        )

        // Then
        XCTAssertFalse(result.isCompliant)
        XCTAssertFalse(result.housingWithinLimit)
        XCTAssertFalse(result.mealsWithinLimit)
    }

    // MARK: - Offer Comparison Tests

    func testCompareOffers() {
        // Given
        let offer1 = JobOffer(
            name: "Hospital A",
            hourlyRate: 35,
            hoursPerWeek: 36,
            housingStipend: 2100,
            mealsStipend: 553
        )
        let offer2 = JobOffer(
            name: "Hospital B",
            hourlyRate: 45,
            hoursPerWeek: 36,
            housingStipend: 1500,
            mealsStipend: 400
        )

        // When
        let comparison = sut.compareOffers([offer1, offer2], federalTaxRate: 0.22, stateTaxRate: 0.0)

        // Then
        XCTAssertEqual(comparison.count, 2)
        XCTAssertNotNil(comparison.first { $0.offer.name == "Hospital A" })
        XCTAssertNotNil(comparison.first { $0.offer.name == "Hospital B" })
    }

    func testCompareOffersRanking() {
        // Given
        let lowPayOffer = JobOffer(
            name: "Low Pay",
            hourlyRate: 25,
            hoursPerWeek: 36,
            housingStipend: 1000,
            mealsStipend: 300
        )
        let highPayOffer = JobOffer(
            name: "High Pay",
            hourlyRate: 50,
            hoursPerWeek: 36,
            housingStipend: 2500,
            mealsStipend: 600
        )

        // When
        let comparison = sut.compareOffers(
            [lowPayOffer, highPayOffer],
            federalTaxRate: 0.22,
            stateTaxRate: 0.0
        )

        // Then - Should be sorted by weekly take home (highest first)
        XCTAssertEqual(comparison.first?.offer.name, "High Pay")
        XCTAssertEqual(comparison.last?.offer.name, "Low Pay")
    }

    func testFindBestOffer() {
        // Given
        let offers = [
            JobOffer(name: "A", hourlyRate: 30, hoursPerWeek: 36, housingStipend: 1500, mealsStipend: 400),
            JobOffer(name: "B", hourlyRate: 40, hoursPerWeek: 36, housingStipend: 2000, mealsStipend: 500),
            JobOffer(name: "C", hourlyRate: 35, hoursPerWeek: 40, housingStipend: 1800, mealsStipend: 450)
        ]

        // When
        let best = sut.findBestOffer(offers, federalTaxRate: 0.22, stateTaxRate: 0.0)

        // Then
        XCTAssertNotNil(best)
        XCTAssertEqual(best?.name, "B") // Highest weekly take home
    }

    // MARK: - Tax Bracket Tests

    func testEstimateFederalTaxBracket() {
        // Test various income levels
        XCTAssertEqual(sut.estimateFederalTaxBracket(annualIncome: 10000), 0.10)
        XCTAssertEqual(sut.estimateFederalTaxBracket(annualIncome: 50000), 0.22)
        XCTAssertEqual(sut.estimateFederalTaxBracket(annualIncome: 100000), 0.24)
        XCTAssertEqual(sut.estimateFederalTaxBracket(annualIncome: 200000), 0.32)
        XCTAssertEqual(sut.estimateFederalTaxBracket(annualIncome: 600000), 0.37)
    }

    // MARK: - Overtime Calculations

    func testCalculateWithOvertime() {
        // Given
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2000,
            mealsStipend: 500,
            overtimeRate: 60 // 1.5x
        )
        let overtimeHours: Double = 8

        // When
        let result = sut.calculateWeeklyWithOvertime(offer: offer, overtimeHours: overtimeHours)

        // Then
        // Regular: 40 * 36 = 1440
        // OT: 60 * 8 = 480
        // Stipends: 2500
        // Total: 1440 + 480 + 2500 = 4420
        XCTAssertEqual(result, 4420)
    }
}

// MARK: - JobOffer Model Tests

final class JobOfferModelTests: XCTestCase {

    func testJobOfferInitialization() {
        // Given/When
        let offer = JobOffer(
            name: "Test Hospital",
            hourlyRate: 42,
            hoursPerWeek: 36,
            housingStipend: 2100,
            mealsStipend: 553,
            travelReimbursement: 500
        )

        // Then
        XCTAssertEqual(offer.name, "Test Hospital")
        XCTAssertEqual(offer.hourlyRate, 42)
        XCTAssertEqual(offer.hoursPerWeek, 36)
        XCTAssertEqual(offer.housingStipend, 2100)
        XCTAssertEqual(offer.mealsStipend, 553)
        XCTAssertEqual(offer.travelReimbursement, 500)
    }

    func testJobOfferDefaultValues() {
        // Given/When
        let offer = JobOffer(
            hourlyRate: 40,
            hoursPerWeek: 36,
            housingStipend: 2000,
            mealsStipend: 500
        )

        // Then
        XCTAssertEqual(offer.name, "Offer")
        XCTAssertEqual(offer.travelReimbursement, 0)
        XCTAssertNil(offer.overtimeRate)
        XCTAssertNil(offer.signOnBonus)
        XCTAssertNil(offer.completionBonus)
    }

    func testJobOfferEquatable() {
        // Given
        let offer1 = JobOffer(hourlyRate: 40, hoursPerWeek: 36, housingStipend: 2000, mealsStipend: 500)
        let offer2 = JobOffer(hourlyRate: 40, hoursPerWeek: 36, housingStipend: 2000, mealsStipend: 500)

        // Then
        XCTAssertEqual(offer1.id, offer1.id)
        XCTAssertNotEqual(offer1.id, offer2.id) // Different UUIDs
    }
}

// MARK: - Decimal Accuracy Helper

extension Decimal {
    static func assertEqual(_ lhs: Decimal, _ rhs: Decimal, accuracy: Decimal, file: StaticString = #file, line: UInt = #line) {
        let diff = abs(lhs - rhs)
        XCTAssertTrue(diff <= accuracy, "\(lhs) is not equal to \(rhs) within accuracy \(accuracy)", file: file, line: line)
    }
}

