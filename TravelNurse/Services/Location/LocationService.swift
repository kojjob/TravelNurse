//
//  LocationService.swift
//  TravelNurse
//
//  GPS location tracking service for mileage tracking
//

import Foundation
import CoreLocation
import Combine

/// Location authorization status for the app
public enum LocationAuthorizationStatus {
    case notDetermined
    case restricted
    case denied
    case authorizedWhenInUse
    case authorizedAlways

    init(from status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorizedWhenInUse:
            self = .authorizedWhenInUse
        case .authorizedAlways:
            self = .authorizedAlways
        @unknown default:
            self = .notDetermined
        }
    }

    var isAuthorized: Bool {
        switch self {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
}

/// Represents a tracked route with coordinates and metadata
public struct TrackedRoute: Codable, Equatable {
    public let coordinates: [Coordinate]
    public let startTime: Date
    public let endTime: Date?
    public let totalDistanceMeters: Double

    public struct Coordinate: Codable, Equatable {
        public let latitude: Double
        public let longitude: Double
        public let timestamp: Date
        public let altitude: Double?
        public let horizontalAccuracy: Double

        public init(from location: CLLocation) {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            self.timestamp = location.timestamp
            self.altitude = location.altitude
            self.horizontalAccuracy = location.horizontalAccuracy
        }
    }

    public init(coordinates: [Coordinate], startTime: Date, endTime: Date?, totalDistanceMeters: Double) {
        self.coordinates = coordinates
        self.startTime = startTime
        self.endTime = endTime
        self.totalDistanceMeters = totalDistanceMeters
    }

    /// Distance in miles
    public var distanceMiles: Double {
        totalDistanceMeters * 0.000621371
    }

    /// Encode route to Data for storage
    public func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }

    /// Decode route from Data
    public static func from(data: Data) -> TrackedRoute? {
        try? JSONDecoder().decode(TrackedRoute.self, from: data)
    }
}

/// Location tracking service for GPS-based mileage tracking
@Observable
public final class LocationService: NSObject {

    // MARK: - Published Properties

    /// Current authorization status
    public private(set) var authorizationStatus: LocationAuthorizationStatus = .notDetermined

    /// Whether tracking is currently active
    public private(set) var isTracking: Bool = false

    /// Current location (updated during tracking)
    public private(set) var currentLocation: CLLocation?

    /// Route being tracked
    public private(set) var currentRoute: [CLLocation] = []

    /// Total distance traveled in current trip (meters)
    public private(set) var currentDistanceMeters: Double = 0

    /// Error message if any
    public private(set) var errorMessage: String?

    /// Whether location services are available
    public var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }

    // MARK: - Private Properties

    private let locationManager: CLLocationManager
    private var trackingStartTime: Date?
    private var lastLocation: CLLocation?

    // Accuracy threshold for location updates (meters)
    private let accuracyThreshold: CLLocationAccuracy = 50

    // Minimum distance between updates (meters)
    private let distanceFilter: CLLocationDistance = 10

    // MARK: - Initialization

    public override init() {
        self.locationManager = CLLocationManager()
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = distanceFilter
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false

        // Set initial authorization status
        authorizationStatus = LocationAuthorizationStatus(from: locationManager.authorizationStatus)
    }

    // MARK: - Authorization

    /// Request location authorization (when in use)
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Request always authorization (for background tracking)
    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Tracking Control

    /// Start tracking location for a trip
    public func startTracking() {
        guard authorizationStatus.isAuthorized else {
            errorMessage = "Location access not authorized"
            return
        }

        guard !isTracking else { return }

        // Reset tracking state
        currentRoute = []
        currentDistanceMeters = 0
        lastLocation = nil
        trackingStartTime = Date()
        errorMessage = nil

        isTracking = true
        locationManager.startUpdatingLocation()
    }

    /// Stop tracking and return the completed route
    @discardableResult
    public func stopTracking() -> TrackedRoute? {
        guard isTracking else { return nil }

        locationManager.stopUpdatingLocation()
        isTracking = false

        guard let startTime = trackingStartTime, !currentRoute.isEmpty else {
            return nil
        }

        let coordinates = currentRoute.map { TrackedRoute.Coordinate(from: $0) }
        let route = TrackedRoute(
            coordinates: coordinates,
            startTime: startTime,
            endTime: Date(),
            totalDistanceMeters: currentDistanceMeters
        )

        // Reset state
        trackingStartTime = nil

        return route
    }

    /// Get current location once (not continuous tracking)
    public func getCurrentLocation() {
        guard authorizationStatus.isAuthorized else {
            errorMessage = "Location access not authorized"
            return
        }

        locationManager.requestLocation()
    }

    // MARK: - Utility Methods

    /// Calculate distance between two coordinates in miles
    public static func distance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation) * 0.000621371 // Convert to miles
    }

    /// Get formatted distance string
    public var formattedCurrentDistance: String {
        let miles = currentDistanceMeters * 0.000621371
        return String(format: "%.1f mi", miles)
    }

    /// Current distance in miles
    public var currentDistanceMiles: Double {
        currentDistanceMeters * 0.000621371
    }

    /// Reverse geocode a location to get address string
    public func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            var components: [String] = []
            if let street = placemark.thoroughfare {
                if let number = placemark.subThoroughfare {
                    components.append("\(number) \(street)")
                } else {
                    components.append(street)
                }
            }
            if let city = placemark.locality {
                components.append(city)
            }
            if let state = placemark.administrativeArea {
                components.append(state)
            }

            return components.isEmpty ? nil : components.joined(separator: ", ")
        } catch {
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = LocationAuthorizationStatus(from: manager.authorizationStatus)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Update current location
        currentLocation = location

        // If tracking, add to route and calculate distance
        if isTracking {
            // Filter out inaccurate readings
            guard location.horizontalAccuracy <= accuracyThreshold else { return }

            // Calculate distance from last location
            if let lastLoc = lastLocation {
                let distance = location.distance(from: lastLoc)
                currentDistanceMeters += distance
            }

            currentRoute.append(location)
            lastLocation = location
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                errorMessage = "Location access denied. Please enable in Settings."
                authorizationStatus = .denied
            case .locationUnknown:
                errorMessage = "Unable to determine location. Please try again."
            default:
                errorMessage = "Location error: \(clError.localizedDescription)"
            }
        } else {
            errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
}
