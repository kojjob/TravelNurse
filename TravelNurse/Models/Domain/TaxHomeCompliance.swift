//
//  TaxHomeCompliance.swift
//  TravelNurse
//
//  Tax home compliance tracking and checklist
//

import Foundation
import SwiftData

/// Tax home compliance tracking for IRS requirements
/// Travel nurses must maintain a legitimate tax home to deduct travel expenses
@Model
public final class TaxHomeCompliance {
    /// Unique identifier
    public var id: UUID

    /// Associated user
    public var user: UserProfile?

    /// Tax year being tracked
    public var taxYear: Int

    /// Days spent at tax home this year
    public var daysAtTaxHome: Int

    /// Last visit to tax home date
    public var lastTaxHomeVisit: Date?

    /// Checklist items (stored as JSON)
    public var checklistItemsData: Data?

    /// Overall compliance score (0-100)
    public var complianceScore: Int

    /// Compliance level (raw value)
    public var complianceLevelRaw: String

    /// Notes/documentation
    public var notes: String?

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Compliance level as enum
    public var complianceLevel: ComplianceLevel {
        get { ComplianceLevel(rawValue: complianceLevelRaw) ?? .unknown }
        set { complianceLevelRaw = newValue.rawValue }
    }

    /// Checklist items decoded from JSON
    public var checklistItems: [ComplianceChecklistItem] {
        get {
            guard let data = checklistItemsData else { return Self.defaultChecklistItems }
            return (try? JSONDecoder().decode([ComplianceChecklistItem].self, from: data)) ?? Self.defaultChecklistItems
        }
        set {
            checklistItemsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Days until 30-day return required (IRS rule)
    public var daysUntil30DayReturn: Int? {
        guard let lastVisit = lastTaxHomeVisit else { return nil }
        let daysSinceVisit = Calendar.current.dateComponents([.day], from: lastVisit, to: Date()).day ?? 0
        return max(0, 30 - daysSinceVisit)
    }

    /// Whether 30-day rule is at risk
    public var thirtyDayRuleAtRisk: Bool {
        guard let daysUntil = daysUntil30DayReturn else { return true }
        return daysUntil <= 7 // Warning when within 7 days
    }

    /// Whether 30-day rule is violated
    public var thirtyDayRuleViolated: Bool {
        guard let daysUntil = daysUntil30DayReturn else { return true }
        return daysUntil <= 0
    }

    /// Completed checklist items count
    public var completedItemsCount: Int {
        checklistItems.filter { $0.status == .complete }.count
    }

    /// Total checklist items count
    public var totalItemsCount: Int {
        checklistItems.count
    }

    /// Checklist completion percentage
    public var checklistCompletionPercentage: Double {
        guard totalItemsCount > 0 else { return 0 }
        return Double(completedItemsCount) / Double(totalItemsCount) * 100
    }

    // MARK: - Initializer

    public init(taxYear: Int? = nil) {
        self.id = UUID()
        self.taxYear = taxYear ?? Calendar.current.component(.year, from: Date())
        self.daysAtTaxHome = 0
        self.complianceScore = 0
        self.complianceLevelRaw = ComplianceLevel.unknown.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
        // Initialize with default checklist
        self.checklistItems = Self.defaultChecklistItems
    }
}

// MARK: - Compliance Calculations

extension TaxHomeCompliance {
    /// Recalculate compliance score based on checklist and other factors
    public func recalculateScore() {
        var score = 0
        var maxScore = 0

        // Checklist items (60% of total)
        for item in checklistItems {
            maxScore += item.weight
            switch item.status {
            case .complete:
                score += item.weight
            case .partial:
                score += item.weight / 2
            case .incomplete, .notApplicable:
                break
            }
        }

        // 30-day rule (20% of total)
        maxScore += 20
        if !thirtyDayRuleViolated {
            score += thirtyDayRuleAtRisk ? 10 : 20
        }

        // Days at tax home (20% of total)
        maxScore += 20
        let targetDays = 30 // Minimum recommended days per year
        let daysScore = min(20, (daysAtTaxHome * 20) / targetDays)
        score += daysScore

        // Calculate percentage
        complianceScore = maxScore > 0 ? (score * 100) / maxScore : 0
        complianceLevel = ComplianceLevel.from(score: complianceScore)
        updatedAt = Date()
    }

    /// Record a visit to tax home
    public func recordTaxHomeVisit(days: Int = 1, date: Date = Date()) {
        daysAtTaxHome += days
        lastTaxHomeVisit = date
        recalculateScore()
    }
}

// MARK: - Default Checklist Items

extension TaxHomeCompliance {
    /// Default IRS tax home compliance checklist items
    nonisolated(unsafe) public static let defaultChecklistItems: [ComplianceChecklistItem] = [
        ComplianceChecklistItem(
            id: "maintain_residence",
            title: "Maintain a residence at tax home",
            description: "You own or rent a home at your tax home location",
            category: .residence,
            weight: 15
        ),
        ComplianceChecklistItem(
            id: "pay_expenses",
            title: "Pay tax home expenses",
            description: "You pay mortgage/rent and utilities at your tax home",
            category: .residence,
            weight: 15
        ),
        ComplianceChecklistItem(
            id: "regular_visits",
            title: "Return regularly to tax home",
            description: "You return to your tax home at least once every 30 days",
            category: .presence,
            weight: 15
        ),
        ComplianceChecklistItem(
            id: "family_ties",
            title: "Family at tax home",
            description: "Family members live at your tax home (spouse, children, etc.)",
            category: .ties,
            weight: 10
        ),
        ComplianceChecklistItem(
            id: "voter_registration",
            title: "Voter registration",
            description: "You're registered to vote at your tax home address",
            category: .ties,
            weight: 5
        ),
        ComplianceChecklistItem(
            id: "drivers_license",
            title: "Driver's license",
            description: "Your driver's license shows your tax home address",
            category: .ties,
            weight: 5
        ),
        ComplianceChecklistItem(
            id: "vehicle_registration",
            title: "Vehicle registration",
            description: "Your vehicle is registered at your tax home address",
            category: .ties,
            weight: 5
        ),
        ComplianceChecklistItem(
            id: "bank_accounts",
            title: "Bank accounts",
            description: "You have bank accounts at your tax home location",
            category: .ties,
            weight: 5
        ),
        ComplianceChecklistItem(
            id: "professional_affiliations",
            title: "Professional affiliations",
            description: "You maintain professional memberships at your tax home",
            category: .ties,
            weight: 5
        ),
        ComplianceChecklistItem(
            id: "religious_civic",
            title: "Community involvement",
            description: "You're involved in religious/civic organizations at tax home",
            category: .ties,
            weight: 5
        )
    ]
}

// MARK: - Checklist Item Model

/// Individual compliance checklist item
public struct ComplianceChecklistItem: Codable, Identifiable, Hashable {
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
        status: ComplianceItemStatus = .incomplete
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
public enum ChecklistCategory: String, Codable, CaseIterable {
    case residence = "Residence"
    case presence = "Physical Presence"
    case ties = "Community Ties"
    case financial = "Financial Ties"
    case documentation = "Documentation"
}
