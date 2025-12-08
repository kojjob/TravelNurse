//
//  NursingLicenseTests.swift
//  TravelNurseTests
//
//  TDD tests for NursingLicense model - written BEFORE implementation
//

import XCTest
import SwiftData
@testable import TravelNurse

// MARK: - LicenseType Tests

final class LicenseTypeTests: XCTestCase {

    func test_rn_displayName() {
        XCTAssertEqual(LicenseType.rn.displayName, "Registered Nurse (RN)")
    }

    func test_lpn_displayName() {
        XCTAssertEqual(LicenseType.lpn.displayName, "Licensed Practical Nurse (LPN)")
    }

    func test_aprn_displayName() {
        XCTAssertEqual(LicenseType.aprn.displayName, "Advanced Practice RN (APRN)")
    }

    func test_np_displayName() {
        XCTAssertEqual(LicenseType.np.displayName, "Nurse Practitioner (NP)")
    }

    func test_crna_displayName() {
        XCTAssertEqual(LicenseType.crna.displayName, "Nurse Anesthetist (CRNA)")
    }

    func test_cns_displayName() {
        XCTAssertEqual(LicenseType.cns.displayName, "Clinical Nurse Specialist (CNS)")
    }

    func test_rn_shortName() {
        XCTAssertEqual(LicenseType.rn.shortName, "RN")
    }

    func test_lpn_shortName() {
        XCTAssertEqual(LicenseType.lpn.shortName, "LPN")
    }
}

// MARK: - LicenseStatus Tests

final class LicenseStatusTests: XCTestCase {

    func test_active_displayName() {
        XCTAssertEqual(LicenseStatus.active.displayName, "Active")
    }

    func test_expired_displayName() {
        XCTAssertEqual(LicenseStatus.expired.displayName, "Expired")
    }

    func test_expiringSoon_displayName() {
        XCTAssertEqual(LicenseStatus.expiringSoon.displayName, "Expiring Soon")
    }

    func test_pending_displayName() {
        XCTAssertEqual(LicenseStatus.pending.displayName, "Pending")
    }

    func test_inactive_displayName() {
        XCTAssertEqual(LicenseStatus.inactive.displayName, "Inactive")
    }
}

// MARK: - NursingLicense Model Tests

final class NursingLicenseModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_setsCorrectValues() {
        let expirationDate = makeDate(year: 2026, month: 6, day: 30)
        let license = NursingLicense(
            licenseNumber: "RN123456",
            licenseType: .rn,
            state: .california,
            expirationDate: expirationDate
        )

        XCTAssertEqual(license.licenseNumber, "RN123456")
        XCTAssertEqual(license.licenseType, .rn)
        XCTAssertEqual(license.state, .california)
        XCTAssertEqual(license.expirationDate, expirationDate)
        XCTAssertTrue(license.isActive)
    }

    func test_init_defaultsToActive() {
        let license = makeLicense()
        XCTAssertTrue(license.isActive)
    }

    func test_init_compactStateFalseByDefault() {
        let license = makeLicense()
        XCTAssertFalse(license.isCompactState)
    }

    // MARK: - Days Until Expiration Tests

    func test_daysUntilExpiration_futureDate_returnsPositive() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let license = makeLicense(expirationDate: futureDate)

        XCTAssertEqual(license.daysUntilExpiration, 30)
    }

    func test_daysUntilExpiration_pastDate_returnsNegative() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let license = makeLicense(expirationDate: pastDate)

        XCTAssertEqual(license.daysUntilExpiration, -10)
    }

    func test_daysUntilExpiration_today_returnsZero() {
        let today = Calendar.current.startOfDay(for: Date())
        let license = makeLicense(expirationDate: today)

        XCTAssertEqual(license.daysUntilExpiration, 0)
    }

    // MARK: - Is Expired Tests

    func test_isExpired_whenPastDate_returnsTrue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let license = makeLicense(expirationDate: pastDate)

        XCTAssertTrue(license.isExpired)
    }

    func test_isExpired_whenFutureDate_returnsFalse() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let license = makeLicense(expirationDate: futureDate)

        XCTAssertFalse(license.isExpired)
    }

    func test_isExpired_whenInactive_returnsTrue() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let license = makeLicense(expirationDate: futureDate, isActive: false)

        XCTAssertTrue(license.isExpired)
    }

    // MARK: - Is Expiring Soon Tests

    func test_isExpiringSoon_within90Days_returnsTrue() {
        let soonDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let license = makeLicense(expirationDate: soonDate)

        XCTAssertTrue(license.isExpiringSoon)
    }

    func test_isExpiringSoon_beyond90Days_returnsFalse() {
        let farDate = Calendar.current.date(byAdding: .day, value: 120, to: Date())!
        let license = makeLicense(expirationDate: farDate)

        XCTAssertFalse(license.isExpiringSoon)
    }

    func test_isExpiringSoon_alreadyExpired_returnsFalse() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let license = makeLicense(expirationDate: pastDate)

        XCTAssertFalse(license.isExpiringSoon)
    }

    // MARK: - Status Tests

    func test_status_whenExpired_returnsExpired() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let license = makeLicense(expirationDate: pastDate)

        XCTAssertEqual(license.status, .expired)
    }

    func test_status_whenInactive_returnsInactive() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let license = makeLicense(expirationDate: futureDate, isActive: false)

        XCTAssertEqual(license.status, .inactive)
    }

    func test_status_whenExpiringSoon_returnsExpiringSoon() {
        let soonDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let license = makeLicense(expirationDate: soonDate)

        XCTAssertEqual(license.status, .expiringSoon)
    }

    func test_status_whenActive_returnsActive() {
        let farDate = Calendar.current.date(byAdding: .day, value: 365, to: Date())!
        let license = makeLicense(expirationDate: farDate)

        XCTAssertEqual(license.status, .active)
    }

    // MARK: - Display Name Tests

    func test_displayName_formatsCorrectly() {
        let license = makeLicense(
            licenseType: .rn,
            state: .california
        )

        XCTAssertEqual(license.displayName, "California RN")
    }

    // MARK: - Compact License Tests

    func test_compactState_whenTrue_allowsMultipleStates() {
        let license = makeLicense(state: .texas)
        license.isCompactState = true

        XCTAssertTrue(license.isCompactState)
    }

    // MARK: - Renew Tests

    func test_renew_updatesExpirationDate() {
        let oldDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let newDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
        let license = makeLicense(expirationDate: oldDate)

        license.renew(newExpirationDate: newDate)

        XCTAssertEqual(license.expirationDate, newDate)
    }

    func test_renew_setsActiveTrue() {
        let license = makeLicense(isActive: false)
        let newDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

        license.renew(newExpirationDate: newDate)

        XCTAssertTrue(license.isActive)
    }

    // MARK: - Helpers

    private func makeLicense(
        licenseNumber: String = "RN123456",
        licenseType: LicenseType = .rn,
        state: USState = .texas,
        expirationDate: Date? = nil,
        isActive: Bool = true
    ) -> NursingLicense {
        let expDate = expirationDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let license = NursingLicense(
            licenseNumber: licenseNumber,
            licenseType: licenseType,
            state: state,
            expirationDate: expDate
        )
        license.isActive = isActive
        return license
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
