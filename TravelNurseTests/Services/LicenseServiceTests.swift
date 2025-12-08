//
//  LicenseServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for LicenseService - written BEFORE implementation
//

import XCTest
import SwiftData
@testable import TravelNurse

@MainActor
final class LicenseServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var sut: LicenseService!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            NursingLicense.self,
            UserProfile.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            sut = LicenseService(modelContext: modelContext)
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Create Tests

    func test_create_insertsIntoContext() {
        let expirationDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

        let license = sut.create(
            licenseNumber: "RN123456",
            licenseType: .rn,
            state: .california,
            expirationDate: expirationDate
        )

        XCTAssertNotNil(license)
        XCTAssertEqual(license.licenseNumber, "RN123456")

        let fetched = sut.fetchAll()
        XCTAssertEqual(fetched.count, 1)
    }

    func test_create_setsDefaultValues() {
        let expirationDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

        let license = sut.create(
            licenseNumber: "RN123456",
            licenseType: .rn,
            state: .texas,
            expirationDate: expirationDate
        )

        XCTAssertTrue(license.isActive)
        XCTAssertFalse(license.isCompactState)
    }

    func test_create_withCompactState() {
        let expirationDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

        let license = sut.create(
            licenseNumber: "RN123456",
            licenseType: .rn,
            state: .texas,
            expirationDate: expirationDate,
            isCompactState: true
        )

        XCTAssertTrue(license.isCompactState)
    }

    // MARK: - Fetch Tests

    func test_fetchAll_returnsAllLicenses() {
        createSampleLicenses()

        let all = sut.fetchAll()

        XCTAssertEqual(all.count, 3)
    }

    func test_fetchActive_returnsOnlyActive() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let active = sut.create(licenseNumber: "RN1", licenseType: .rn, state: .texas, expirationDate: expDate)
        let inactive = sut.create(licenseNumber: "RN2", licenseType: .rn, state: .california, expirationDate: expDate)
        inactive.isActive = false

        let fetched = sut.fetchActive()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, active.id)
    }

    func test_fetchByState_filtersCorrectly() {
        createSampleLicenses()

        let texasLicenses = sut.fetchByState(.texas)

        XCTAssertEqual(texasLicenses.count, 1)
        XCTAssertEqual(texasLicenses.first?.state, .texas)
    }

    func test_fetchByType_filtersCorrectly() {
        createSampleLicenses()

        let rnLicenses = sut.fetchByType(.rn)

        XCTAssertGreaterThanOrEqual(rnLicenses.count, 1)
        XCTAssertTrue(rnLicenses.allSatisfy { $0.licenseType == .rn })
    }

    func test_fetchExpiringSoon_returnsOnlyExpiringSoon() {
        let soonDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let farDate = Calendar.current.date(byAdding: .day, value: 180, to: Date())!

        _ = sut.create(licenseNumber: "SOON", licenseType: .rn, state: .texas, expirationDate: soonDate)
        _ = sut.create(licenseNumber: "FAR", licenseType: .rn, state: .california, expirationDate: farDate)

        let expiring = sut.fetchExpiringSoon()

        XCTAssertEqual(expiring.count, 1)
        XCTAssertEqual(expiring.first?.licenseNumber, "SOON")
    }

    func test_fetchExpired_returnsOnlyExpired() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .day, value: 180, to: Date())!

        _ = sut.create(licenseNumber: "EXPIRED", licenseType: .rn, state: .texas, expirationDate: pastDate)
        _ = sut.create(licenseNumber: "VALID", licenseType: .rn, state: .california, expirationDate: futureDate)

        let expired = sut.fetchExpired()

        XCTAssertEqual(expired.count, 1)
        XCTAssertEqual(expired.first?.licenseNumber, "EXPIRED")
    }

    // MARK: - Update Tests

    func test_update_changesExpirationDate() {
        let oldDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let newDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
        let license = sut.create(licenseNumber: "RN1", licenseType: .rn, state: .texas, expirationDate: oldDate)

        sut.update(license, expirationDate: newDate)

        XCTAssertEqual(license.expirationDate, newDate)
    }

    func test_update_changesLicenseNumber() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let license = sut.create(licenseNumber: "OLD123", licenseType: .rn, state: .texas, expirationDate: expDate)

        sut.update(license, licenseNumber: "NEW456")

        XCTAssertEqual(license.licenseNumber, "NEW456")
    }

    // MARK: - Renew Tests

    func test_renew_updatesExpirationAndActivates() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let newDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
        let license = sut.create(licenseNumber: "RN1", licenseType: .rn, state: .texas, expirationDate: oldDate)

        sut.renew(license, newExpirationDate: newDate)

        XCTAssertEqual(license.expirationDate, newDate)
        XCTAssertTrue(license.isActive)
    }

    // MARK: - Delete Tests

    func test_delete_removesFromContext() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let license = sut.create(licenseNumber: "RN1", licenseType: .rn, state: .texas, expirationDate: expDate)

        sut.delete(license)

        let all = sut.fetchAll()
        XCTAssertEqual(all.count, 0)
    }

    // MARK: - Deactivate/Activate Tests

    func test_deactivate_setsInactive() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let license = sut.create(licenseNumber: "RN1", licenseType: .rn, state: .texas, expirationDate: expDate)

        sut.deactivate(license)

        XCTAssertFalse(license.isActive)
    }

    func test_activate_setsActive() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let license = sut.create(licenseNumber: "RN1", licenseType: .rn, state: .texas, expirationDate: expDate)
        license.isActive = false

        sut.activate(license)

        XCTAssertTrue(license.isActive)
    }

    // MARK: - Summary Tests

    func test_summary_countsCorrectly() {
        let activeDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let soonDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let expiredDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

        _ = sut.create(licenseNumber: "ACTIVE", licenseType: .rn, state: .texas, expirationDate: activeDate)
        _ = sut.create(licenseNumber: "SOON", licenseType: .lpn, state: .california, expirationDate: soonDate)
        _ = sut.create(licenseNumber: "EXPIRED", licenseType: .rn, state: .florida, expirationDate: expiredDate)

        let summary = sut.summary()

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.activeCount, 2) // ACTIVE + SOON (not expired)
        XCTAssertEqual(summary.expiringSoonCount, 1)
        XCTAssertEqual(summary.expiredCount, 1)
    }

    func test_summary_listsUniqueStates() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        _ = sut.create(licenseNumber: "TX1", licenseType: .rn, state: .texas, expirationDate: expDate)
        _ = sut.create(licenseNumber: "CA1", licenseType: .rn, state: .california, expirationDate: expDate)
        _ = sut.create(licenseNumber: "TX2", licenseType: .lpn, state: .texas, expirationDate: expDate)

        let summary = sut.summary()

        XCTAssertEqual(summary.statesCount, 2)
    }

    // MARK: - Compact License Tests

    func test_fetchCompactLicenses_returnsOnlyCompact() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let compact = sut.create(licenseNumber: "COMPACT", licenseType: .rn, state: .texas, expirationDate: expDate, isCompactState: true)
        _ = sut.create(licenseNumber: "SINGLE", licenseType: .rn, state: .california, expirationDate: expDate, isCompactState: false)

        let compactLicenses = sut.fetchCompactLicenses()

        XCTAssertEqual(compactLicenses.count, 1)
        XCTAssertEqual(compactLicenses.first?.id, compact.id)
    }

    // MARK: - Helpers

    private func createSampleLicenses() {
        let expDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        _ = sut.create(licenseNumber: "TX-RN-123", licenseType: .rn, state: .texas, expirationDate: expDate)
        _ = sut.create(licenseNumber: "CA-RN-456", licenseType: .rn, state: .california, expirationDate: expDate)
        _ = sut.create(licenseNumber: "FL-LPN-789", licenseType: .lpn, state: .florida, expirationDate: expDate)
    }
}
