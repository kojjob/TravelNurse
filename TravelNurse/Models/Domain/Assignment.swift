//
//  Assignment.swift
//  TravelNurse
//
//  Travel nursing assignment model
//

import Foundation
import SwiftData

/// Represents a travel nursing assignment/contract
@Model
public final class Assignment {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// Facility/Hospital name
    public var facilityName: String

    /// Staffing agency name
    public var agencyName: String

    /// Assignment location
    @Relationship(deleteRule: .cascade)
    public var location: Address?

    /// Contract start date
    public var startDate: Date

    /// Contract end date
    public var endDate: Date

    /// Current assignment status (raw value for persistence)
    public var statusRaw: String

    /// Weekly guaranteed hours
    public var weeklyHours: Double

    /// Shift type (Day, Night, Rotating)
    public var shiftType: String

    /// Unit/Department name
    public var unitName: String?

    /// Pay breakdown details
    @Relationship(deleteRule: .cascade)
    public var payBreakdown: PayBreakdown?

    /// Notes about this assignment
    public var notes: String?

    /// Whether this assignment has been extended
    public var wasExtended: Bool

    /// Original end date (before extension)
    public var originalEndDate: Date?

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Status as enum
    public var status: AssignmentStatus {
        get { AssignmentStatus(rawValue: statusRaw) ?? .upcoming }
        set { statusRaw = newValue.rawValue }
    }

    /// Assignment state (from location)
    public var state: USState? {
        location?.state
    }

    /// Contract duration in weeks
    public var durationWeeks: Int {
        Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0
    }

    /// Contract duration in days
    public var durationDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    /// Days remaining (if active)
    public var daysRemaining: Int? {
        guard status.isInProgress else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }

    /// Progress percentage (0-100)
    public var progressPercentage: Double {
        guard status.isInProgress || status == .completed else { return 0 }
        let total = Double(durationDays)
        guard total > 0 else { return 0 }
        let elapsed = Double(Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0)
        return min(100, max(0, (elapsed / total) * 100))
    }

    /// Formatted date range
    public var dateRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Total expected gross pay for assignment
    public var totalExpectedPay: Decimal {
        guard let pay = payBreakdown else { return 0 }
        return pay.weeklyGross * Decimal(durationWeeks)
    }

    /// Whether this assignment is in a no-income-tax state
    @MainActor public var isInNoTaxState: Bool {
        state?.hasNoIncomeTax ?? false
    }

    // MARK: - Initializer

    public init(
        facilityName: String,
        agencyName: String,
        startDate: Date,
        endDate: Date,
        weeklyHours: Double = 36,
        shiftType: String = "Day",
        unitName: String? = nil,
        status: AssignmentStatus = .upcoming
    ) {
        self.id = UUID()
        self.facilityName = facilityName
        self.agencyName = agencyName
        self.startDate = startDate
        self.endDate = endDate
        self.statusRaw = status.rawValue
        self.weeklyHours = weeklyHours
        self.shiftType = shiftType
        self.unitName = unitName
        self.wasExtended = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - IRS Compliance

extension Assignment {
    /// Maximum assignment duration at one location (IRS one-year rule)
    public static let maxDurationMonths = 12

    /// Check if approaching one-year limit
    public var isApproachingOneYearLimit: Bool {
        durationDays >= 300 // ~10 months, warning threshold
    }

    /// Check if at or over one-year limit
    public var exceedsOneYearLimit: Bool {
        durationDays >= 365
    }
}

// MARK: - Common Shift Types

extension Assignment {
    public static let shiftTypes = [
        "Day (7a-7p)",
        "Night (7p-7a)",
        "Day (7a-3p)",
        "Evening (3p-11p)",
        "Night (11p-7a)",
        "Rotating",
        "Variable"
    ]
}

