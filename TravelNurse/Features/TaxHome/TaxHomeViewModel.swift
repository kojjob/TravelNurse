//
//  TaxHomeViewModel.swift
//  TravelNurse
//
//  ViewModel for Tax Home Compliance feature
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel managing Tax Home Compliance state and business logic
@MainActor
@Observable
final class TaxHomeViewModel {

    // MARK: - State

    /// Current compliance record
    private(set) var compliance: TaxHomeCompliance?

    /// Loading state
    private(set) var isLoading = false

    /// Error message if something goes wrong
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showError = false

    /// Whether to show record visit confirmation
    var showRecordVisitConfirmation = false

    /// Whether to show success toast
    var showSuccessToast = false

    /// Success message for toast
    private(set) var successMessage: String?

    // MARK: - Dependencies

    private let serviceContainer: ServiceContainer

    // MARK: - Computed Properties

    /// Current compliance score (0-100)
    var complianceScore: Int {
        compliance?.complianceScore ?? 0
    }

    /// Current compliance level
    var complianceLevel: ComplianceLevel {
        compliance?.complianceLevel ?? .unknown
    }

    /// Days spent at tax home this year
    var daysAtTaxHome: Int {
        compliance?.daysAtTaxHome ?? 0
    }

    /// Days until 30-day return is required
    var daysUntil30DayReturn: Int {
        compliance?.daysUntil30DayReturn ?? 30
    }

    /// Whether 30-day rule is at risk
    var thirtyDayRuleAtRisk: Bool {
        compliance?.thirtyDayRuleAtRisk ?? false
    }

    /// Whether 30-day rule is violated
    var thirtyDayRuleViolated: Bool {
        compliance?.thirtyDayRuleViolated ?? false
    }

    /// Last tax home visit date
    var lastTaxHomeVisit: Date? {
        compliance?.lastTaxHomeVisit
    }

    /// Formatted last visit date
    var lastVisitFormatted: String {
        guard let date = lastTaxHomeVisit else {
            return "No visits recorded"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Checklist items organized by category
    var checklistItemsByCategory: [ChecklistCategory: [ComplianceChecklistItem]] {
        guard let items = compliance?.checklistItems else { return [:] }
        return Dictionary(grouping: items) { $0.category }
    }

    /// Categories in display order
    var categories: [ChecklistCategory] {
        [.residence, .presence, .ties, .financial, .documentation]
    }

    /// Total checklist items count
    var totalChecklistItems: Int {
        compliance?.checklistItems.count ?? 0
    }

    /// Completed checklist items count
    var completedChecklistItems: Int {
        compliance?.checklistItems.filter { $0.status == .complete }.count ?? 0
    }

    /// Checklist completion percentage
    var checklistCompletionPercentage: Double {
        guard totalChecklistItems > 0 else { return 0 }
        return Double(completedChecklistItems) / Double(totalChecklistItems)
    }

    /// 30-day rule status color
    var thirtyDayStatusColor: Color {
        if thirtyDayRuleViolated {
            return TNColors.error
        } else if thirtyDayRuleAtRisk {
            return TNColors.warning
        } else {
            return TNColors.success
        }
    }

    /// 30-day rule status text
    var thirtyDayStatusText: String {
        if thirtyDayRuleViolated {
            return "30-Day Rule Violated"
        } else if thirtyDayRuleAtRisk {
            return "Visit Required Soon"
        } else {
            return "On Track"
        }
    }

    /// Progress toward 30-day limit (0.0 to 1.0)
    var thirtyDayProgress: Double {
        let daysSinceVisit = 30 - daysUntil30DayReturn
        return min(1.0, max(0.0, Double(daysSinceVisit) / 30.0))
    }

    // MARK: - Initialization

    init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
    }

    // MARK: - Actions

    /// Load or create the current compliance record
    func loadCompliance() async {
        isLoading = true
        errorMessage = nil

        do {
            let service = try serviceContainer.getComplianceService()
            compliance = service.getOrCreateCurrent()
        } catch {
            errorMessage = "Failed to load compliance data: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    /// Record a tax home visit
    func recordTaxHomeVisit(date: Date = Date(), daysStayed: Int = 1) async {
        guard compliance != nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            let service = try serviceContainer.getComplianceService()
            service.recordTaxHomeVisit(days: daysStayed, date: date)

            // Reload to get updated data
            compliance = service.getOrCreateCurrent()

            successMessage = "Tax home visit recorded!"
            showSuccessToast = true
        } catch {
            errorMessage = "Failed to record visit: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    /// Update a checklist item's status
    func updateChecklistItem(id: String, isCompleted: Bool, notes: String? = nil) async {
        guard compliance != nil else { return }

        do {
            let service = try serviceContainer.getComplianceService()
            let status: ComplianceItemStatus = isCompleted ? .complete : .incomplete
            service.updateChecklistItem(itemId: id, status: status, notes: notes)

            // Reload to get updated score
            compliance = service.getOrCreateCurrent()
        } catch {
            errorMessage = "Failed to update checklist item: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Toggle a checklist item's completion status
    func toggleChecklistItem(id: String) async {
        guard let item = compliance?.checklistItems.first(where: { $0.id == id }) else { return }
        let isCurrentlyComplete = item.status == .complete
        await updateChecklistItem(id: id, isCompleted: !isCurrentlyComplete)
    }

    /// Get checklist items for a specific category
    func items(for category: ChecklistCategory) -> [ComplianceChecklistItem] {
        checklistItemsByCategory[category] ?? []
    }

    /// Format category name for display
    func formatCategoryName(_ category: ChecklistCategory) -> String {
        switch category {
        case .residence:
            return "Residence"
        case .presence:
            return "Physical Presence"
        case .ties:
            return "Community Ties"
        case .financial:
            return "Financial"
        case .documentation:
            return "Documentation"
        }
    }

    /// Get icon for category
    func iconForCategory(_ category: ChecklistCategory) -> String {
        switch category {
        case .residence:
            return "house.fill"
        case .presence:
            return "calendar.badge.clock"
        case .ties:
            return "person.3.fill"
        case .financial:
            return "dollarsign.circle.fill"
        case .documentation:
            return "doc.text.fill"
        }
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    /// Dismiss success toast
    func dismissSuccessToast() {
        showSuccessToast = false
        successMessage = nil
    }
}

// MARK: - Preview Helper

extension TaxHomeViewModel {
    /// Create a preview instance with mock data
    static var preview: TaxHomeViewModel {
        let viewModel = TaxHomeViewModel()
        // Preview will load data when view appears
        return viewModel
    }
}
