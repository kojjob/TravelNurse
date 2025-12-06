//
//  Address.swift
//  TravelNurse
//
//  Address model for locations (tax home, assignments, facilities)
//

import Foundation
import SwiftData

/// Represents a physical address
@Model
public final class Address {
    /// Street address line 1
    public var street1: String

    /// Street address line 2 (apt, suite, etc.)
    public var street2: String?

    /// City name
    public var city: String

    /// State (using USState enum raw value for persistence)
    public var stateRaw: String

    /// ZIP code
    public var zipCode: String

    /// Country (defaults to USA)
    public var country: String

    /// Optional coordinates for mapping
    public var latitude: Double?
    public var longitude: Double?

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// State as USState enum
    public var state: USState? {
        get { USState(rawValue: stateRaw) }
        set { stateRaw = newValue?.rawValue ?? "" }
    }

    /// Full formatted address string
    public var formatted: String {
        var lines: [String] = []
        lines.append(street1)
        if let street2, !street2.isEmpty {
            lines.append(street2)
        }
        lines.append("\(city), \(stateRaw) \(zipCode)")
        return lines.joined(separator: "\n")
    }

    /// Single line address
    public var singleLine: String {
        var parts: [String] = [street1]
        if let street2, !street2.isEmpty {
            parts.append(street2)
        }
        parts.append("\(city), \(stateRaw) \(zipCode)")
        return parts.joined(separator: ", ")
    }

    /// City and state only
    public var cityState: String {
        "\(city), \(stateRaw)"
    }

    /// Whether coordinates are available
    public var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    // MARK: - Initializer

    public init(
        street1: String,
        street2: String? = nil,
        city: String,
        state: USState,
        zipCode: String,
        country: String = "USA",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.street1 = street1
        self.street2 = street2
        self.city = city
        self.stateRaw = state.rawValue
        self.zipCode = zipCode
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension Address {
    /// Validates the address has required fields
    public var isValid: Bool {
        !street1.isEmpty && !city.isEmpty && !stateRaw.isEmpty && !zipCode.isEmpty
    }

    /// Validates ZIP code format (basic US format)
    public var hasValidZipCode: Bool {
        let zipPattern = "^\\d{5}(-\\d{4})?$"
        return zipCode.range(of: zipPattern, options: .regularExpression) != nil
    }
}
