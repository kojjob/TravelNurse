//
//  ComplianceChecklistItem.swift
//  TravelNurse
//
//  Compliance checklist item and related types for tax home tracking
//

import Foundation

/// Individual compliance checklist item
public struct ComplianceChecklistItem: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let category: ChecklistCategory
    public let weight: Int
    public var status: ComplianceItemStatus
    public var notes: String?
    public var documentPath: String?
    public var lastUpdated: Date?

    public nonisolated init(
        id: String,
        title: String,
        description: String,
        category: ChecklistCategory,
        weight: Int,
        status: ComplianceItemStatus
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.weight = weight
        self.status = status
    }
}

/// Categories for checklist items
public enum ChecklistCategory: String, Codable, CaseIterable, Sendable {
    case residence = "Residence"
    case presence = "Physical Presence"
    case ties = "Community Ties"
    case financial = "Financial Ties"
    case documentation = "Documentation"
}

// MARK: - Default Checklist Items

/// Default IRS tax home compliance checklist items
public nonisolated(unsafe) let defaultTaxHomeChecklistItems: [ComplianceChecklistItem] = [
    ComplianceChecklistItem(
        id: "maintain_residence",
        title: "Maintain a residence at tax home",
        description: "You own or rent a home at your tax home location",
        category: .residence,
        weight: 15,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "pay_expenses",
        title: "Pay tax home expenses",
        description: "You pay mortgage/rent and utilities at your tax home",
        category: .residence,
        weight: 15,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "regular_visits",
        title: "Return regularly to tax home",
        description: "You return to your tax home at least once every 30 days",
        category: .presence,
        weight: 15,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "family_ties",
        title: "Family at tax home",
        description: "Family members live at your tax home (spouse, children, etc.)",
        category: .ties,
        weight: 10,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "voter_registration",
        title: "Voter registration",
        description: "You're registered to vote at your tax home address",
        category: .ties,
        weight: 5,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "drivers_license",
        title: "Driver's license",
        description: "Your driver's license shows your tax home address",
        category: .ties,
        weight: 5,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "vehicle_registration",
        title: "Vehicle registration",
        description: "Your vehicle is registered at your tax home address",
        category: .ties,
        weight: 5,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "bank_accounts",
        title: "Bank accounts",
        description: "You have bank accounts at your tax home location",
        category: .ties,
        weight: 5,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "professional_affiliations",
        title: "Professional affiliations",
        description: "You maintain professional memberships at your tax home",
        category: .ties,
        weight: 5,
        status: .incomplete
    ),
    ComplianceChecklistItem(
        id: "religious_civic",
        title: "Community involvement",
        description: "You're involved in religious/civic organizations at tax home",
        category: .ties,
        weight: 5,
        status: .incomplete
    )
]
