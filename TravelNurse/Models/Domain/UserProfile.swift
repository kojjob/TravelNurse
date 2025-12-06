//
//  UserProfile.swift
//  TravelNurse
//
//  User profile model for the travel nurse
//

import Foundation
import SwiftData

/// Main user profile for the travel nurse
@Model
public final class UserProfile {
    /// User's first name
    public var firstName: String

    /// User's last name
    public var lastName: String

    /// User's email address
    public var email: String

    /// Phone number
    public var phone: String?

    /// Nursing license number
    public var licenseNumber: String?

    /// Primary nursing specialty
    public var specialty: String?

    /// Years of nursing experience
    public var yearsExperience: Int?

    /// Tax home address (permanent residence)
    @Relationship(deleteRule: .cascade)
    public var taxHomeAddress: Address?

    /// Current mailing address (if different from tax home)
    @Relationship(deleteRule: .cascade)
    public var mailingAddress: Address?

    /// Associated assignments
    @Relationship(deleteRule: .cascade, inverse: \Assignment.user)
    public var assignments: [Assignment]

    /// Associated expenses
    @Relationship(deleteRule: .cascade, inverse: \Expense.user)
    public var expenses: [Expense]

    /// Associated mileage trips
    @Relationship(deleteRule: .cascade, inverse: \MileageTrip.user)
    public var mileageTrips: [MileageTrip]

    /// Tax year preference (defaults to current calendar year)
    public var activeTaxYear: Int

    /// Whether user has completed onboarding
    public var hasCompletedOnboarding: Bool

    /// Profile creation date
    public var createdAt: Date

    /// Last profile update
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Full name
    public var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Initials for avatar
    public var initials: String {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    /// Current active assignment (if any)
    public var currentAssignment: Assignment? {
        assignments.first { $0.status == .active || $0.status == .extended }
    }

    /// Total assignments count
    public var totalAssignments: Int {
        assignments.count
    }

    /// Completed assignments count
    public var completedAssignments: Int {
        assignments.filter { $0.status == .completed }.count
    }

    // MARK: - Initializer

    public init(
        firstName: String,
        lastName: String,
        email: String,
        phone: String? = nil,
        licenseNumber: String? = nil,
        specialty: String? = nil,
        yearsExperience: Int? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.specialty = specialty
        self.yearsExperience = yearsExperience
        self.assignments = []
        self.expenses = []
        self.mileageTrips = []
        self.activeTaxYear = Calendar.current.component(.year, from: Date())
        self.hasCompletedOnboarding = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Tax Home Status

extension UserProfile {
    /// Whether user has a valid tax home address set
    public var hasTaxHome: Bool {
        taxHomeAddress != nil && taxHomeAddress?.isValid == true
    }

    /// Tax home state (if set)
    public var taxHomeState: USState? {
        taxHomeAddress?.state
    }
}

// MARK: - Common Nursing Specialties

extension UserProfile {
    /// Common nursing specialties for selection
    public static let commonSpecialties: [String] = [
        "Medical-Surgical",
        "Intensive Care Unit (ICU)",
        "Emergency Room (ER)",
        "Operating Room (OR)",
        "Labor & Delivery (L&D)",
        "Pediatrics (Peds)",
        "Neonatal ICU (NICU)",
        "Cardiac Care",
        "Oncology",
        "Telemetry",
        "Step-Down Unit",
        "Post-Anesthesia Care (PACU)",
        "Dialysis",
        "Rehabilitation",
        "Psychiatric/Mental Health",
        "Home Health",
        "Long-Term Care",
        "Cath Lab",
        "Interventional Radiology",
        "Endoscopy"
    ]
}
