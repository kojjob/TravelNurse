//
//  NursingLicense.swift
//  TravelNurse
//
//  Model for tracking nursing licenses across multiple states
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - License Type

/// Types of nursing licenses
public enum LicenseType: String, CaseIterable, Codable, Identifiable, Sendable {
    case rn = "RN"
    case lpn = "LPN"
    case lvn = "LVN"
    case aprn = "APRN"
    case np = "NP"
    case crna = "CRNA"
    case cns = "CNS"
    case cnm = "CNM"

    public var id: String { rawValue }

    /// Full display name
    public var displayName: String {
        switch self {
        case .rn: return "Registered Nurse (RN)"
        case .lpn: return "Licensed Practical Nurse (LPN)"
        case .lvn: return "Licensed Vocational Nurse (LVN)"
        case .aprn: return "Advanced Practice RN (APRN)"
        case .np: return "Nurse Practitioner (NP)"
        case .crna: return "Nurse Anesthetist (CRNA)"
        case .cns: return "Clinical Nurse Specialist (CNS)"
        case .cnm: return "Certified Nurse Midwife (CNM)"
        }
    }

    /// Short name (abbreviation)
    public var shortName: String {
        rawValue
    }

    /// Icon name for UI
    public var iconName: String {
        switch self {
        case .rn, .lpn, .lvn: return "cross.case.fill"
        case .aprn, .np: return "stethoscope"
        case .crna: return "lungs.fill"
        case .cns: return "brain.head.profile"
        case .cnm: return "figure.and.child.holdinghands"
        }
    }
}

// MARK: - License Status

/// Current status of a nursing license
public enum LicenseStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case active
    case expired
    case expiringSoon
    case pending
    case inactive

    public var id: String { rawValue }

    /// Display name for UI
    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .expired: return "Expired"
        case .expiringSoon: return "Expiring Soon"
        case .pending: return "Pending"
        case .inactive: return "Inactive"
        }
    }

    /// Color for status badge
    public var color: Color {
        switch self {
        case .active: return TNColors.success
        case .expired: return TNColors.error
        case .expiringSoon: return TNColors.warning
        case .pending: return TNColors.primary
        case .inactive: return TNColors.textSecondary
        }
    }

    /// Icon name for status
    public var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .expired: return "xmark.circle.fill"
        case .expiringSoon: return "exclamationmark.triangle.fill"
        case .pending: return "clock.fill"
        case .inactive: return "pause.circle.fill"
        }
    }
}

// MARK: - Nursing License Model

/// A nursing license for a specific state
@Model
public final class NursingLicense {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// License number issued by the state
    public var licenseNumber: String

    /// Type of license (raw value for persistence)
    public var licenseTypeRaw: String

    /// State that issued the license (raw value for persistence)
    public var stateRaw: String

    /// Expiration date of the license
    public var expirationDate: Date

    /// Date license was issued (optional)
    public var issueDate: Date?

    /// Whether this license is currently active
    public var isActive: Bool

    /// Whether this is a compact/multi-state license
    public var isCompactState: Bool

    /// Notes about this license
    public var notes: String?

    /// Verification URL for the state board
    public var verificationURL: String?

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// License type as enum
    public var licenseType: LicenseType {
        get { LicenseType(rawValue: licenseTypeRaw) ?? .rn }
        set { licenseTypeRaw = newValue.rawValue }
    }

    /// State as enum
    public var state: USState {
        get { USState(rawValue: stateRaw) ?? .texas }
        set { stateRaw = newValue.rawValue }
    }

    /// Days until expiration (negative if expired)
    public var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiry = calendar.startOfDay(for: expirationDate)
        return calendar.dateComponents([.day], from: today, to: expiry).day ?? 0
    }

    /// Whether the license has expired
    public var isExpired: Bool {
        !isActive || expirationDate < Date()
    }

    /// Whether the license is expiring within 90 days
    public var isExpiringSoon: Bool {
        guard !isExpired else { return false }
        return daysUntilExpiration <= 90 && daysUntilExpiration > 0
    }

    /// Current status of the license
    public var status: LicenseStatus {
        if !isActive { return .inactive }
        if isExpired { return .expired }
        if isExpiringSoon { return .expiringSoon }
        return .active
    }

    /// Display name combining state and license type
    @MainActor public var displayName: String {
        "\(state.fullName) \(licenseType.shortName)"
    }

    /// Short display name
    @MainActor public var shortDisplayName: String {
        "\(state.rawValue) \(licenseType.shortName)"
    }

    /// Formatted expiration date
    @MainActor public var formattedExpirationDate: String {
        TNFormatters.date(expirationDate)
    }

    /// Expiration status text
    public var expirationText: String {
        if isExpired {
            return "Expired \(abs(daysUntilExpiration)) days ago"
        } else if daysUntilExpiration == 0 {
            return "Expires today"
        } else if daysUntilExpiration == 1 {
            return "Expires tomorrow"
        } else if daysUntilExpiration <= 30 {
            return "Expires in \(daysUntilExpiration) days"
        } else if daysUntilExpiration <= 90 {
            return "Expires in \(daysUntilExpiration / 7) weeks"
        } else {
            return "Expires in \(daysUntilExpiration / 30) months"
        }
    }

    // MARK: - Initializer

    public init(
        licenseNumber: String,
        licenseType: LicenseType,
        state: USState,
        expirationDate: Date,
        issueDate: Date? = nil,
        isCompactState: Bool = false,
        notes: String? = nil,
        verificationURL: String? = nil
    ) {
        self.id = UUID()
        self.licenseNumber = licenseNumber
        self.licenseTypeRaw = licenseType.rawValue
        self.stateRaw = state.rawValue
        self.expirationDate = expirationDate
        self.issueDate = issueDate
        self.isActive = true
        self.isCompactState = isCompactState
        self.notes = notes
        self.verificationURL = verificationURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// Renew the license with a new expiration date
    public func renew(newExpirationDate: Date) {
        expirationDate = newExpirationDate
        isActive = true
        updatedAt = Date()
    }

    /// Deactivate the license
    public func deactivate() {
        isActive = false
        updatedAt = Date()
    }

    /// Activate the license
    public func activate() {
        isActive = true
        updatedAt = Date()
    }
}

// MARK: - Queries

extension NursingLicense {
    /// Predicate for active licenses
    static var activePredicate: Predicate<NursingLicense> {
        #Predicate<NursingLicense> { license in
            license.isActive == true
        }
    }

    /// Predicate for filtering by state
    static func statePredicate(_ state: USState) -> Predicate<NursingLicense> {
        let stateRaw = state.rawValue
        return #Predicate<NursingLicense> { license in
            license.stateRaw == stateRaw
        }
    }

    /// Predicate for filtering by license type
    static func typePredicate(_ type: LicenseType) -> Predicate<NursingLicense> {
        let typeRaw = type.rawValue
        return #Predicate<NursingLicense> { license in
            license.licenseTypeRaw == typeRaw
        }
    }

    /// Predicate for compact licenses
    static var compactPredicate: Predicate<NursingLicense> {
        #Predicate<NursingLicense> { license in
            license.isCompactState == true
        }
    }
}

// MARK: - Preview Helper

extension NursingLicense {
    static var preview: NursingLicense {
        let expirationDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        return NursingLicense(
            licenseNumber: "RN-123456",
            licenseType: .rn,
            state: .texas,
            expirationDate: expirationDate,
            isCompactState: true
        )
    }

    static var previews: [NursingLicense] {
        let calendar = Calendar.current
        return [
            NursingLicense(
                licenseNumber: "RN-TX-123456",
                licenseType: .rn,
                state: .texas,
                expirationDate: calendar.date(byAdding: .year, value: 1, to: Date())!,
                isCompactState: true
            ),
            NursingLicense(
                licenseNumber: "RN-CA-789012",
                licenseType: .rn,
                state: .california,
                expirationDate: calendar.date(byAdding: .day, value: 45, to: Date())!
            ),
            NursingLicense(
                licenseNumber: "LPN-FL-345678",
                licenseType: .lpn,
                state: .florida,
                expirationDate: calendar.date(byAdding: .day, value: -30, to: Date())!
            )
        ]
    }
}
