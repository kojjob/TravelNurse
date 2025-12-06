//
//  ComplianceLevelTests.swift
//  TravelNurseTests
//
//  Unit tests for ComplianceLevel enum
//

import Testing
@testable import TravelNurse

@Suite("ComplianceLevel Tests")
struct ComplianceLevelTests {

    // MARK: - Score Calculation Tests

    @Test("ComplianceLevel.from(score:) returns correct levels")
    func testFromScore() {
        // Excellent: 90-100
        #expect(ComplianceLevel.from(score: 100) == .excellent)
        #expect(ComplianceLevel.from(score: 95) == .excellent)
        #expect(ComplianceLevel.from(score: 90) == .excellent)

        // Good: 70-89
        #expect(ComplianceLevel.from(score: 89) == .good)
        #expect(ComplianceLevel.from(score: 75) == .good)
        #expect(ComplianceLevel.from(score: 70) == .good)

        // At Risk: 50-69
        #expect(ComplianceLevel.from(score: 69) == .atRisk)
        #expect(ComplianceLevel.from(score: 60) == .atRisk)
        #expect(ComplianceLevel.from(score: 50) == .atRisk)

        // Non-Compliant: 0-49
        #expect(ComplianceLevel.from(score: 49) == .nonCompliant)
        #expect(ComplianceLevel.from(score: 25) == .nonCompliant)
        #expect(ComplianceLevel.from(score: 0) == .nonCompliant)

        // Edge cases
        #expect(ComplianceLevel.from(score: -1) == .unknown)
        #expect(ComplianceLevel.from(score: 101) == .unknown)
    }

    // MARK: - Display Properties Tests

    @Test("ComplianceLevel display names are correct")
    func testDisplayNames() {
        #expect(ComplianceLevel.excellent.displayName == "Excellent")
        #expect(ComplianceLevel.good.displayName == "Good")
        #expect(ComplianceLevel.atRisk.displayName == "At Risk")
        #expect(ComplianceLevel.nonCompliant.displayName == "Non-Compliant")
        #expect(ComplianceLevel.unknown.displayName == "Unknown")
    }

    @Test("ComplianceLevel descriptions are informative")
    func testDescriptions() {
        #expect(ComplianceLevel.excellent.description.contains("compliant"))
        #expect(ComplianceLevel.atRisk.description.contains("questioned"))
        #expect(ComplianceLevel.nonCompliant.description.contains("Immediate action"))
    }

    @Test("ComplianceLevel icons are SF Symbols")
    func testIconNames() {
        #expect(ComplianceLevel.excellent.iconName == "checkmark.shield.fill")
        #expect(ComplianceLevel.atRisk.iconName == "exclamationmark.triangle.fill")
        #expect(ComplianceLevel.nonCompliant.iconName == "xmark.shield.fill")
    }

    // MARK: - Minimum Score Tests

    @Test("ComplianceLevel minimum scores are correct")
    func testMinimumScores() {
        #expect(ComplianceLevel.excellent.minimumScore == 90)
        #expect(ComplianceLevel.good.minimumScore == 70)
        #expect(ComplianceLevel.atRisk.minimumScore == 50)
        #expect(ComplianceLevel.nonCompliant.minimumScore == 0)
    }
}

@Suite("ComplianceItemStatus Tests")
struct ComplianceItemStatusTests {

    @Test("ComplianceItemStatus display names are correct")
    func testDisplayNames() {
        #expect(ComplianceItemStatus.complete.displayName == "Complete")
        #expect(ComplianceItemStatus.incomplete.displayName == "Incomplete")
        #expect(ComplianceItemStatus.partial.displayName == "Partial")
        #expect(ComplianceItemStatus.notApplicable.displayName == "N/A")
    }

    @Test("ComplianceItemStatus icons are SF Symbols")
    func testIconNames() {
        #expect(ComplianceItemStatus.complete.iconName == "checkmark.circle.fill")
        #expect(ComplianceItemStatus.incomplete.iconName == "circle")
    }
}
