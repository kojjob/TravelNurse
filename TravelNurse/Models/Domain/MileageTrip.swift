//
//  MileageTrip.swift
//  TravelNurse
//
//  GPS-tracked mileage trip model
//

import Foundation
import SwiftData
import CoreLocation

/// A tracked mileage trip for tax deduction
@Model
public final class MileageTrip {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// Associated assignment (optional)
    public var assignment: Assignment?

    /// Trip purpose/description
    public var purpose: String

    /// Trip type (raw value for persistence)
    public var tripTypeRaw: String

    /// Start location description
    public var startLocationName: String

    /// End location description
    public var endLocationName: String

    /// Start coordinates (latitude)
    public var startLatitude: Double?

    /// Start coordinates (longitude)
    public var startLongitude: Double?

    /// End coordinates (latitude)
    public var endLatitude: Double?

    /// End coordinates (longitude)
    public var endLongitude: Double?

    /// Trip start time
    public var startTime: Date

    /// Trip end time
    public var endTime: Date?

    /// Total distance in miles
    public var distanceMiles: Double

    /// IRS mileage rate at time of trip (cents per mile)
    public var mileageRate: Decimal

    /// Whether trip was auto-tracked via GPS
    public var isAutoTracked: Bool

    /// GPS route data (encoded polyline or coordinates)
    @Attribute(.externalStorage)
    public var routeData: Data?

    /// Notes about this trip
    public var notes: String?

    /// Tax year
    public var taxYear: Int

    /// Whether this has been exported/reported
    public var isReported: Bool

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Trip type as enum
    public var tripType: MileageTripType {
        get { MileageTripType(rawValue: tripTypeRaw) ?? .workRelated }
        set { tripTypeRaw = newValue.rawValue }
    }

    /// Calculated deduction amount
    public var deductionAmount: Decimal {
        Decimal(distanceMiles) * mileageRate
    }

    /// Formatted deduction amount
    public var deductionFormatted: String {
        TNFormatters.currency(deductionAmount)
    }

    /// Formatted distance
    public var distanceFormatted: String {
        TNFormatters.miles(distanceMiles)
    }

    /// Trip duration
    public var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    /// Formatted duration
    public var durationFormatted: String? {
        guard let duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Date formatted for display
    public var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startTime)
    }

    /// Start location as CLLocationCoordinate2D
    public var startCoordinate: CLLocationCoordinate2D? {
        guard let lat = startLatitude, let lon = startLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// End location as CLLocationCoordinate2D
    public var endCoordinate: CLLocationCoordinate2D? {
        guard let lat = endLatitude, let lon = endLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: - Initializer

    public init(
        purpose: String,
        tripType: MileageTripType = .workRelated,
        startLocationName: String,
        endLocationName: String,
        startTime: Date = Date(),
        distanceMiles: Double = 0,
        mileageRate: Decimal = MileageTrip.currentIRSRate,
        isAutoTracked: Bool = false
    ) {
        self.id = UUID()
        self.purpose = purpose
        self.tripTypeRaw = tripType.rawValue
        self.startLocationName = startLocationName
        self.endLocationName = endLocationName
        self.startTime = startTime
        self.distanceMiles = distanceMiles
        self.mileageRate = mileageRate
        self.isAutoTracked = isAutoTracked
        self.taxYear = Calendar.current.component(.year, from: startTime)
        self.isReported = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - IRS Mileage Rates

extension MileageTrip {
    /// Current IRS standard mileage rate (2024: 67 cents per mile)
    public static let currentIRSRate: Decimal = 0.67

    /// Historical IRS rates by year
    public static let irsRatesByYear: [Int: Decimal] = [
        2024: 0.67,
        2023: 0.655,
        2022: 0.625,  // July-Dec was 0.625
        2021: 0.56,
        2020: 0.575
    ]

    /// Get IRS rate for a specific year
    public static func irsRate(for year: Int) -> Decimal {
        irsRatesByYear[year] ?? currentIRSRate
    }
}

// MARK: - Trip Types

/// Types of mileage trips for categorization
public enum MileageTripType: String, CaseIterable, Codable, Identifiable {
    case workRelated = "work"              // To/from assignment
    case taxHomeTravel = "tax_home"        // Travel to maintain tax home
    case licensure = "licensure"           // License/certification related
    case professionalDevelopment = "prof_dev"  // Conferences, CE
    case medicalAppointment = "medical"    // Work-related medical
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .workRelated: return "Work Related"
        case .taxHomeTravel: return "Tax Home Travel"
        case .licensure: return "Licensure"
        case .professionalDevelopment: return "Professional Development"
        case .medicalAppointment: return "Medical Appointment"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .workRelated: return "briefcase.fill"
        case .taxHomeTravel: return "house.fill"
        case .licensure: return "doc.badge.plus"
        case .professionalDevelopment: return "graduationcap.fill"
        case .medicalAppointment: return "stethoscope"
        case .other: return "car.fill"
        }
    }
}
