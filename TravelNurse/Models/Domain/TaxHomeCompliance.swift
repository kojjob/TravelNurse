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
            guard let data = checklistItemsData else { return ComplianceChecklistItem.defaults }
            return (try? JSONDecoder().decode([ComplianceChecklistItem].self, from: data)) ?? ComplianceChecklistItem.defaults
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
        self.checklistItems = ComplianceChecklistItem.defaults
    }
}

// MARK: - Compliance Calculations

extension TaxHomeCompliance {
    /// Recalculate compliance score based on checklist and other factors
    @MainActor public func recalculateScore() {
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
    @MainActor public func recordTaxHomeVisit(days: Int = 1, date: Date = Date()) {
        daysAtTaxHome += days
        lastTaxHomeVisit = date
        recalculateScore()
    }
}


// MARK: - Checklist Item Model

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
        status: ComplianceItemStatus = .incomplete
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.weight = weight
        self.status = status
    }

    /// Default IRS tax home compliance checklist items
    /// Using nonisolated computed property to avoid MainActor isolation issues
    public nonisolated static var defaults: [ComplianceChecklistItem] {
        [
            ComplianceChecklistItem(id: "residence-proof", title: "Proof of Residence", description: "Maintain lease or ownership documents at tax home.", category: .residence, weight: 10),
            ComplianceChecklistItem(id: "mail-forward", title: "Mail Forwarding", description: "Set up mail forwarding to tax home address.", category: .residence, weight: 5),
            ComplianceChecklistItem(id: "presence-days", title: "Physical Presence", description: "Spend required days at tax home.", category: .presence, weight: 15),
            ComplianceChecklistItem(id: "community-ties", title: "Community Ties", description: "Maintain local memberships and relationships.", category: .ties, weight: 10),
            ComplianceChecklistItem(id: "financial-ties", title: "Financial Ties", description: "Keep local bank accounts and financial activities.", category: .financial, weight: 10),
            ComplianceChecklistItem(id: "documentation", title: "Documentation", description: "Keep receipts and records of travel and lodging.", category: .documentation, weight: 10)
        ]
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
