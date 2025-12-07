//
//  MileageViewModel.swift
//  TravelNurse
//
//  ViewModel for mileage tracking with GPS
//

import Foundation
import SwiftUI
import CoreLocation

/// ViewModel for mileage tracking functionality
@MainActor
@Observable
public final class MileageViewModel {

    // MARK: - State

    /// Whether data is loading
    public var isLoading: Bool = false

    /// Error message if any
    public var errorMessage: String?

    /// Current tracking state
    public var isTracking: Bool {
        locationService?.isTracking ?? false
    }

    /// Active trip being tracked
    public var activeTrip: MileageTrip?

    /// Recent trips for display
    public var recentTrips: [MileageTrip] = []

    /// Selected trip type for new trip
    public var selectedTripType: MileageTripType = .workRelated

    /// Purpose description for new trip
    public var tripPurpose: String = ""

    /// Show trip type picker
    public var showTripTypePicker: Bool = false

    /// Show trip completed alert
    public var showTripCompletedAlert: Bool = false

    /// Completed trip for alert
    public var completedTrip: MileageTrip?

    // MARK: - Statistics

    /// Total miles tracked this year
    public var yearTotalMiles: Double = 0

    /// Total deduction amount this year
    public var yearTotalDeduction: Decimal = 0

    /// Total trips this year
    public var yearTripCount: Int = 0

    // MARK: - Services

    private var mileageService: MileageService?
    private var locationService: LocationService?

    // MARK: - Computed Properties

    /// Current distance formatted for display
    public var currentDistanceFormatted: String {
        guard let service = locationService else { return "0.0 mi" }
        return service.formattedCurrentDistance
    }

    /// Current distance in miles
    public var currentDistanceMiles: Double {
        locationService?.currentDistanceMiles ?? 0
    }

    /// Location authorization status
    public var authorizationStatus: LocationAuthorizationStatus {
        locationService?.authorizationStatus ?? .notDetermined
    }

    /// Whether location services are available
    public var isLocationEnabled: Bool {
        locationService?.isLocationServicesEnabled ?? false
    }

    /// Whether we can start tracking
    public var canStartTracking: Bool {
        authorizationStatus.isAuthorized && !isTracking
    }

    /// Formatted year total miles
    public var formattedYearMiles: String {
        String(format: "%.1f mi", yearTotalMiles)
    }

    /// Formatted year total deduction
    public var formattedYearDeduction: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: yearTotalDeduction as NSDecimalNumber) ?? "$0.00"
    }

    /// Current IRS rate per mile
    public var currentIRSRate: String {
        let rate = NSDecimalNumber(decimal: MileageTrip.currentIRSRate).doubleValue
        return String(format: "$%.2f/mi", rate)
    }

    // MARK: - Initialization

    public init() {
        // Services will be configured when view appears
    }

    /// Configure services from ServiceContainer
    public func configure() {
        do {
            mileageService = try ServiceContainer.shared.getMileageService()
            locationService = try ServiceContainer.shared.getLocationService()
        } catch {
            errorMessage = "Failed to initialize services"
        }
    }

    // MARK: - Data Loading

    /// Load data for display
    public func loadData() {
        guard let mileageService else { return }

        isLoading = true
        defer { isLoading = false }

        let currentYear = Calendar.current.component(.year, from: Date())

        // Load statistics
        yearTotalMiles = mileageService.totalMiles(forYear: currentYear)
        yearTotalDeduction = mileageService.totalDeduction(forYear: currentYear)
        yearTripCount = mileageService.tripCount(forYear: currentYear)

        // Load recent trips
        recentTrips = mileageService.fetchRecentOrEmpty(limit: 10)

        // Check for active trip (trip without end time)
        activeTrip = mileageService.fetchAllOrEmpty().first { $0.endTime == nil }
    }

    /// Refresh data
    public func refresh() {
        loadData()
    }

    // MARK: - Location Authorization

    /// Request location permission
    public func requestLocationPermission() {
        locationService?.requestAuthorization()
    }

    // MARK: - Trip Tracking

    /// Start tracking a new trip
    public func startTracking() {
        guard let mileageService, let locationService else {
            errorMessage = "Services not configured"
            return
        }

        guard authorizationStatus.isAuthorized else {
            requestLocationPermission()
            return
        }

        // Start location tracking
        locationService.startTracking()

        // Create trip record
        let purpose = tripPurpose.isEmpty ? selectedTripType.displayName : tripPurpose
        activeTrip = mileageService.startTripQuietly(
            purpose: purpose,
            tripType: selectedTripType,
            startLocation: "Starting location..."
        )

        // Update start location asynchronously
        Task {
            await updateStartLocation()
        }

        // Reset input fields
        tripPurpose = ""
    }

    /// Stop tracking current trip
    public func stopTracking() {
        guard let mileageService, let locationService, let trip = activeTrip else { return }

        // Stop location tracking and get route
        guard let trackedRoute = locationService.stopTracking() else {
            errorMessage = "Failed to complete trip"
            return
        }

        // Update trip with final data
        mileageService.endTripQuietly(
            trip,
            endLocation: "Destination",
            distance: trackedRoute.distanceMiles
        )

        // Store route data
        if let routeData = trackedRoute.toData() {
            trip.routeData = routeData
        }

        // Set end coordinates
        if let lastCoord = trackedRoute.coordinates.last {
            trip.endLatitude = lastCoord.latitude
            trip.endLongitude = lastCoord.longitude
        }

        trip.isAutoTracked = true

        // Update end location asynchronously
        Task {
            await updateEndLocation(trip)
        }

        // Show completion alert
        completedTrip = trip
        showTripCompletedAlert = true

        // Clear active trip and refresh data
        activeTrip = nil
        loadData()
    }

    /// Cancel current tracking without saving
    public func cancelTracking() {
        guard let mileageService, let locationService, let trip = activeTrip else { return }

        _ = locationService.stopTracking()
        mileageService.deleteQuietly(trip)
        activeTrip = nil
    }

    // MARK: - Manual Trip Entry

    /// Add a manual trip entry
    public func addManualTrip(
        purpose: String,
        type: MileageTripType,
        distance: Double,
        date: Date = Date()
    ) {
        guard let mileageService else { return }

        let trip = MileageTrip(
            purpose: purpose,
            tripType: type,
            startLocationName: "Manual entry",
            endLocationName: "Manual entry",
            startTime: date,
            distanceMiles: distance,
            isAutoTracked: false
        )
        trip.endTime = date
        mileageService.createQuietly(trip)

        loadData()
    }

    /// Delete a trip
    public func deleteTrip(_ trip: MileageTrip) {
        guard let mileageService else { return }
        mileageService.deleteQuietly(trip)
        loadData()
    }

    // MARK: - Private Helpers

    /// Update start location with geocoded address
    private func updateStartLocation() async {
        guard let locationService, let trip = activeTrip,
              let location = locationService.currentLocation else { return }

        // Set coordinates
        trip.startLatitude = location.coordinate.latitude
        trip.startLongitude = location.coordinate.longitude

        // Geocode address
        if let address = await locationService.reverseGeocode(location) {
            trip.startLocationName = address
        }
    }

    /// Update end location with geocoded address
    private func updateEndLocation(_ trip: MileageTrip) async {
        guard let locationService, let location = locationService.currentLocation else { return }

        if let address = await locationService.reverseGeocode(location) {
            trip.endLocationName = address
        }
    }
}
