//
//  USStateTests.swift
//  TravelNurseTests
//
//  Unit tests for USState enum
//

import Testing
@testable import TravelNurse

@Suite("USState Tests")
struct USStateTests {

    // MARK: - Initialization Tests

    @Test("USState raw value initialization")
    func testRawValueInitialization() {
        #expect(USState(rawValue: "CA") == .california)
        #expect(USState(rawValue: "TX") == .texas)
        #expect(USState(rawValue: "FL") == .florida)
        #expect(USState(rawValue: "INVALID") == nil)
    }

    @Test("USState raw value returns correct abbreviation")
    func testRawValue() {
        #expect(USState.california.rawValue == "CA")
        #expect(USState.newYork.rawValue == "NY")
        #expect(USState.districtOfColumbia.rawValue == "DC")
    }

    // MARK: - Full Name Tests

    @Test("USState full name returns correct state name")
    func testFullName() {
        #expect(USState.california.fullName == "California")
        #expect(USState.newYork.fullName == "New York")
        #expect(USState.northCarolina.fullName == "North Carolina")
        #expect(USState.districtOfColumbia.fullName == "District of Columbia")
    }

    // MARK: - No Income Tax Tests

    @Test("No income tax states identified correctly")
    func testNoIncomeTaxStates() {
        // States with no income tax
        #expect(USState.alaska.hasNoIncomeTax == true)
        #expect(USState.florida.hasNoIncomeTax == true)
        #expect(USState.nevada.hasNoIncomeTax == true)
        #expect(USState.southDakota.hasNoIncomeTax == true)
        #expect(USState.texas.hasNoIncomeTax == true)
        #expect(USState.washington.hasNoIncomeTax == true)
        #expect(USState.wyoming.hasNoIncomeTax == true)

        // States with income tax
        #expect(USState.california.hasNoIncomeTax == false)
        #expect(USState.newYork.hasNoIncomeTax == false)
        #expect(USState.illinois.hasNoIncomeTax == false)
    }

    @Test("No income tax states static list contains correct states")
    func testNoIncomeTaxStatesList() {
        let noTaxStates = USState.noIncomeTaxStates

        #expect(noTaxStates.count == 7)
        #expect(noTaxStates.contains(.texas))
        #expect(noTaxStates.contains(.florida))
        #expect(!noTaxStates.contains(.california))
    }

    // MARK: - Identifiable Tests

    @Test("USState id matches raw value")
    func testIdentifiable() {
        #expect(USState.california.id == "CA")
        #expect(USState.texas.id == "TX")
    }

    // MARK: - CaseIterable Tests

    @Test("USState all cases contains all states")
    func testAllCases() {
        // 50 states + DC = 51
        #expect(USState.allCases.count == 51)
    }
}
