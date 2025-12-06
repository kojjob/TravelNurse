//
//  MileageTripTests.swift
//  TravelNurseTests
//
//  Unit tests for MileageTrip model
//

import Testing
import Foundation
@testable import TravelNurse

@Suite("MileageTrip Tests")
struct MileageTripTests {

    // MARK: - Initialization Tests

    @Test("MileageTrip initializes with correct default values")
    func testInitialization() {
        let trip = MileageTrip(
            purpose: "Work commute",
            startLocationName: "Home",
            endLocationName: "Hospital"
        )

        #expect(trip.purpose == "Work commute")
        #expect(trip.startLocationName == "Home")
        #expect(trip.endLocationName == "Hospital")
        #expect(trip.tripType == .workRelated)
        #expect(trip.mileageRate == MileageTrip.currentIRSRate)
        #expect(trip.isAutoTracked == false)
        #expect(trip.isReported == false)
    }

    // MARK: - Deduction Calculation Tests

    @Test("Deduction amount calculates correctly")
    func testDeductionAmount() {
        let trip = MileageTrip(
            purpose: "Work commute",
            startLocationName: "Home",
            endLocationName: "Hospital",
            distanceMiles: 100,
            mileageRate: 0.67
        )

        // 100 miles * 0.67 = $67.00
        #expect(trip.deductionAmount == 67.00)
    }

    @Test("Deduction formatted includes currency")
    func testDeductionFormatted() {
        let trip = MileageTrip(
            purpose: "Work",
            startLocationName: "A",
            endLocationName: "B",
            distanceMiles: 100,
            mileageRate: 0.67
        )

        #expect(trip.deductionFormatted.contains("$"))
        #expect(trip.deductionFormatted.contains("67"))
    }

    // MARK: - Distance Formatting Tests

    @Test("Distance formatted correctly")
    func testDistanceFormatted() {
        let trip = MileageTrip(
            purpose: "Work",
            startLocationName: "A",
            endLocationName: "B",
            distanceMiles: 25.5
        )

        #expect(trip.distanceFormatted == "25.5 mi")
    }

    // MARK: - Duration Tests

    @Test("Duration calculated when end time set")
    func testDuration() {
        let start = Date()
        let trip = MileageTrip(
            purpose: "Work",
            startLocationName: "A",
            endLocationName: "B",
            startTime: start
        )
        trip.endTime = start.addingTimeInterval(3600) // 1 hour later

        #expect(trip.duration == 3600)
    }

    @Test("Duration is nil when end time not set")
    func testDurationNil() {
        let trip = MileageTrip(
            purpose: "Work",
            startLocationName: "A",
            endLocationName: "B"
        )

        #expect(trip.duration == nil)
    }

    @Test("Duration formatted correctly")
    func testDurationFormatted() {
        let start = Date()
        let trip = MileageTrip(
            purpose: "Work",
            startLocationName: "A",
            endLocationName: "B",
            startTime: start
        )

        // 1 hour 30 minutes
        trip.endTime = start.addingTimeInterval(5400)
        #expect(trip.durationFormatted == "1h 30m")

        // 45 minutes
        trip.endTime = start.addingTimeInterval(2700)
        #expect(trip.durationFormatted == "45m")
    }

    // MARK: - IRS Rate Tests

    @Test("Current IRS rate is set correctly")
    func testCurrentIRSRate() {
        // 2024 rate
        #expect(MileageTrip.currentIRSRate == 0.67)
    }

    @Test("Historical IRS rates are available")
    func testHistoricalRates() {
        #expect(MileageTrip.irsRate(for: 2024) == 0.67)
        #expect(MileageTrip.irsRate(for: 2023) == 0.655)
        #expect(MileageTrip.irsRate(for: 2022) == 0.625)
    }

    @Test("Unknown year returns current rate")
    func testUnknownYearRate() {
        #expect(MileageTrip.irsRate(for: 2030) == MileageTrip.currentIRSRate)
    }

    // MARK: - Trip Type Tests

    @Test("Trip type enum works correctly")
    func testTripType() {
        let trip = MileageTrip(
            purpose: "License renewal",
            tripType: .licensure,
            startLocationName: "Home",
            endLocationName: "Board of Nursing"
        )

        #expect(trip.tripType == .licensure)
        #expect(trip.tripType.displayName == "Licensure")
    }

    @Test("All trip types have display names and icons")
    func testTripTypeProperties() {
        for tripType in MileageTripType.allCases {
            #expect(!tripType.displayName.isEmpty)
            #expect(!tripType.iconName.isEmpty)
        }
    }

    // MARK: - Tax Year Tests

    @Test("Tax year set from start time")
    func testTaxYear() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        let trip = MileageTrip(
            purpose: "Work",
            startLocationName: "A",
            endLocationName: "B"
        )

        #expect(trip.taxYear == currentYear)
    }
}
