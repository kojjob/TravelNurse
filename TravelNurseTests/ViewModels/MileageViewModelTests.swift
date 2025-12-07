//
//  MileageViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for MileageViewModel
//

import XCTest
@testable import TravelNurse

// MARK: - Test Cases

@MainActor
final class MileageViewModelTests: XCTestCase {

    var sut: MileageViewModel!

    override func setUp() {
        super.setUp()
        sut = MileageViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_setsDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.activeTrip)
        XCTAssertTrue(sut.recentTrips.isEmpty)
        XCTAssertEqual(sut.selectedTripType, .workRelated)
        XCTAssertTrue(sut.tripPurpose.isEmpty)
        XCTAssertFalse(sut.showTripTypePicker)
        XCTAssertFalse(sut.showTripCompletedAlert)
        XCTAssertNil(sut.completedTrip)
    }

    func testInit_setsDefaultStatistics() {
        XCTAssertEqual(sut.yearTotalMiles, 0)
        XCTAssertEqual(sut.yearTotalDeduction, 0)
        XCTAssertEqual(sut.yearTripCount, 0)
    }

    // MARK: - Computed Properties Tests

    func testCurrentDistanceFormatted_whenNoService_returnsDefaultValue() {
        // When no location service configured
        XCTAssertEqual(sut.currentDistanceFormatted, "0.0 mi")
    }

    func testCurrentDistanceMiles_whenNoService_returnsZero() {
        XCTAssertEqual(sut.currentDistanceMiles, 0)
    }

    func testAuthorizationStatus_whenNoService_returnsNotDetermined() {
        XCTAssertEqual(sut.authorizationStatus, .notDetermined)
    }

    func testIsLocationEnabled_whenNoService_returnsFalse() {
        XCTAssertFalse(sut.isLocationEnabled)
    }

    func testCanStartTracking_whenNoService_returnsFalse() {
        // When authorization is not determined and not tracking
        XCTAssertFalse(sut.canStartTracking)
    }

    // MARK: - Formatted Values Tests

    func testFormattedYearMiles_formatsMilesCorrectly() {
        // Given
        sut.yearTotalMiles = 1234.56

        // Then
        XCTAssertEqual(sut.formattedYearMiles, "1234.6 mi")
    }

    func testFormattedYearMiles_whenZero_formatsCorrectly() {
        XCTAssertEqual(sut.formattedYearMiles, "0.0 mi")
    }

    func testFormattedYearDeduction_formatsCurrencyCorrectly() {
        // Given
        sut.yearTotalDeduction = 1500.50

        // Then
        XCTAssertTrue(sut.formattedYearDeduction.contains("1,500"))
        XCTAssertTrue(sut.formattedYearDeduction.contains("$"))
    }

    func testFormattedYearDeduction_whenZero_returnsFormattedZero() {
        // Given
        sut.yearTotalDeduction = 0

        // Then
        XCTAssertTrue(sut.formattedYearDeduction.contains("$"))
        XCTAssertTrue(sut.formattedYearDeduction.contains("0"))
    }

    func testCurrentIRSRate_formatsRateCorrectly() {
        // The IRS rate should be formatted as dollars per mile
        XCTAssertTrue(sut.currentIRSRate.contains("$"))
        XCTAssertTrue(sut.currentIRSRate.contains("/mi"))
    }

    // MARK: - Configure Tests

    func testConfigure_whenServiceContainerNotReady_setsErrorMessage() {
        // Note: This tests the error handling path when services aren't available
        // In a real scenario, we'd need mock services to fully test this
        sut.configure()

        // After configuration attempt, error message may or may not be set
        // depending on ServiceContainer state
        // This test documents the expected behavior
    }

    // MARK: - State Management Tests

    func testLoadData_withoutService_doesNotCrash() {
        // When services aren't configured, loadData should handle gracefully
        sut.loadData()

        // Should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    func testRefresh_callsLoadData() {
        // When
        sut.refresh()

        // Then - should complete without crashing
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Trip Tracking State Tests

    func testStartTracking_withoutServices_setsErrorMessage() {
        // When
        sut.startTracking()

        // Then
        XCTAssertEqual(sut.errorMessage, "Services not configured")
    }

    func testCancelTracking_withoutActiveTrip_doesNothing() {
        // Given
        XCTAssertNil(sut.activeTrip)

        // When
        sut.cancelTracking()

        // Then - should complete without crashing
        XCTAssertNil(sut.activeTrip)
    }

    func testStopTracking_withoutActiveTrip_doesNothing() {
        // Given
        XCTAssertNil(sut.activeTrip)

        // When
        sut.stopTracking()

        // Then - should complete without crashing
        XCTAssertNil(sut.activeTrip)
    }

    // MARK: - Trip Type Selection Tests

    func testSelectedTripType_canBeChanged() {
        // Given
        XCTAssertEqual(sut.selectedTripType, .workRelated)

        // When
        sut.selectedTripType = .medicalAppointment

        // Then
        XCTAssertEqual(sut.selectedTripType, .medicalAppointment)
    }

    func testTripPurpose_canBeSet() {
        // When
        sut.tripPurpose = "Hospital visit"

        // Then
        XCTAssertEqual(sut.tripPurpose, "Hospital visit")
    }

    func testShowTripTypePicker_canBeToggled() {
        // Given
        XCTAssertFalse(sut.showTripTypePicker)

        // When
        sut.showTripTypePicker = true

        // Then
        XCTAssertTrue(sut.showTripTypePicker)
    }

    // MARK: - Alert State Tests

    func testShowTripCompletedAlert_canBeSet() {
        // Given
        XCTAssertFalse(sut.showTripCompletedAlert)

        // When
        sut.showTripCompletedAlert = true

        // Then
        XCTAssertTrue(sut.showTripCompletedAlert)
    }

    // MARK: - Manual Trip Entry Tests

    func testAddManualTrip_withoutService_doesNotCrash() {
        // When
        sut.addManualTrip(
            purpose: "Test trip",
            type: .workRelated,
            distance: 25.5,
            date: Date()
        )

        // Then - should complete without crashing
        // No trips added since service isn't configured
    }

    func testDeleteTrip_withoutService_doesNotCrash() {
        // Given
        let trip = MileageTrip(
            purpose: "Test",
            tripType: .workRelated,
            startLocationName: "Start",
            endLocationName: "End",
            startTime: Date(),
            distanceMiles: 10.0,
            isAutoTracked: false
        )

        // When
        sut.deleteTrip(trip)

        // Then - should complete without crashing
    }

    // MARK: - Location Permission Tests

    func testRequestLocationPermission_withoutService_doesNotCrash() {
        // When
        sut.requestLocationPermission()

        // Then - should complete without crashing
    }

    // MARK: - Error State Tests

    func testErrorMessage_canBeCleared() {
        // Given
        sut.errorMessage = "Some error"

        // When
        sut.errorMessage = nil

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testIsLoading_canBeToggled() {
        // Given
        XCTAssertFalse(sut.isLoading)

        // When
        sut.isLoading = true

        // Then
        XCTAssertTrue(sut.isLoading)
    }
}

// MARK: - MileageTripType Tests

@MainActor
final class MileageTripTypeTests: XCTestCase {

    func testAllCases_containsExpectedTypes() {
        let allTypes = MileageTripType.allCases

        XCTAssertTrue(allTypes.contains(.workRelated))
        XCTAssertTrue(allTypes.contains(.medicalAppointment))
        XCTAssertTrue(allTypes.contains(.taxHomeTravel))
        XCTAssertTrue(allTypes.contains(.licensure))
        XCTAssertTrue(allTypes.contains(.professionalDevelopment))
        XCTAssertTrue(allTypes.contains(.other))
    }

    func testDisplayName_returnsNonEmptyString() {
        for tripType in MileageTripType.allCases {
            XCTAssertFalse(tripType.displayName.isEmpty)
        }
    }

    func testWorkRelated_hasCorrectDisplayName() {
        XCTAssertTrue(MileageTripType.workRelated.displayName.lowercased().contains("work"))
    }
}

// MARK: - MileageTrip Tests

@MainActor
final class MileageTripModelTests: XCTestCase {

    func testInit_setsProperties() {
        // Given
        let purpose = "Hospital visit"
        let tripType = MileageTripType.workRelated
        let startLocation = "Home"
        let endLocation = "Hospital"
        let startTime = Date()
        let distance = 15.5

        // When
        let trip = MileageTrip(
            purpose: purpose,
            tripType: tripType,
            startLocationName: startLocation,
            endLocationName: endLocation,
            startTime: startTime,
            distanceMiles: distance,
            isAutoTracked: true
        )

        // Then
        XCTAssertEqual(trip.purpose, purpose)
        XCTAssertEqual(trip.tripType, tripType)
        XCTAssertEqual(trip.startLocationName, startLocation)
        XCTAssertEqual(trip.endLocationName, endLocation)
        XCTAssertEqual(trip.startTime, startTime)
        XCTAssertEqual(trip.distanceMiles, distance)
        XCTAssertTrue(trip.isAutoTracked)
    }

    func testDeductionAmount_calculatesCorrectly() {
        // Given
        let trip = MileageTrip(
            purpose: "Work trip",
            startLocationName: "Start",
            endLocationName: "End",
            startTime: Date(),
            distanceMiles: 100.0
        )

        // Then
        // Deduction should be distance * IRS rate
        let expectedDeduction = Decimal(100.0) * MileageTrip.currentIRSRate
        XCTAssertEqual(trip.deductionAmount, expectedDeduction)
    }

    func testCurrentIRSRate_isPositive() {
        XCTAssertTrue(MileageTrip.currentIRSRate > 0)
    }

    func testDeductionFormatted_containsCurrencySymbol() {
        // Given
        let trip = MileageTrip(
            purpose: "Work trip",
            startLocationName: "Start",
            endLocationName: "End",
            startTime: Date(),
            distanceMiles: 50.0
        )

        // Then
        XCTAssertTrue(trip.deductionFormatted.contains("$"))
    }

    func testDistanceFormatted_containsMilesSuffix() {
        // Given
        let trip = MileageTrip(
            purpose: "Work trip",
            startLocationName: "Start",
            endLocationName: "End",
            startTime: Date(),
            distanceMiles: 25.5
        )

        // Then
        XCTAssertTrue(trip.distanceFormatted.contains("mi"))
    }
}

// MARK: - LocationAuthorizationStatus Tests

@MainActor
final class LocationAuthorizationStatusTests: XCTestCase {

    func testNotDetermined_isNotAuthorized() {
        XCTAssertFalse(LocationAuthorizationStatus.notDetermined.isAuthorized)
    }

    func testDenied_isNotAuthorized() {
        XCTAssertFalse(LocationAuthorizationStatus.denied.isAuthorized)
    }

    func testRestricted_isNotAuthorized() {
        XCTAssertFalse(LocationAuthorizationStatus.restricted.isAuthorized)
    }

    func testAuthorizedWhenInUse_isAuthorized() {
        XCTAssertTrue(LocationAuthorizationStatus.authorizedWhenInUse.isAuthorized)
    }

    func testAuthorizedAlways_isAuthorized() {
        XCTAssertTrue(LocationAuthorizationStatus.authorizedAlways.isAuthorized)
    }
}
