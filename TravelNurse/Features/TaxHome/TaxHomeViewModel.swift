//
//  TaxHomeViewModel.swift
//  TravelNurse
//
//  ViewModel for tax home compliance tracking
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel for TaxHomeView managing compliance data and checklist state
@Observable
final class TaxHomeViewModel {

    // MARK: - Published Properties

    var compliance: TaxHomeCompliance?
    var isLoading = false
    var errorMessage: String?
    var showingRecordVisitSheet = false
    var visitDaysToRecord = 1

    // MARK: - Computed Properties

    var complianceScore: Int {
        compliance?.complianceScore ?? 0
    }

    var complianceLevel: ComplianceLevel {
        compliance?.complianceLevel ?? .unknown
    }

    var daysAtTaxHome: Int {
        compliance?.daysAtTaxHome ?? 0
    }

    var daysUntil30DayReturn: Int? {
        compliance?.daysUntil30DayReturn
    }

    var thirtyDayRuleAtRisk: Bool {
        compliance?.thirtyDayRuleAtRisk ?? false
    }

    var thirtyDayRuleViolated: Bool {
        compliance?.thirtyDayRuleViolated ?? false
    }

    var lastVisitDate: Date? {
        compliance?.lastTaxHomeVisit
    }

    var checklistItems: [ComplianceChecklistItem] {
        compliance?.checklistItems ?? []
    }

    var completedItemsCount: Int {
        compliance?.completedItemsCount ?? 0
    }

    var totalItemsCount: Int {
        compliance?.totalItemsCount ?? 0
    }

    var checklistCompletionPercentage: Double {
        compliance?.checklistCompletionPercentage ?? 0
    }

    // MARK: - Grouped Checklist Items

    var residenceItems: [ComplianceChecklistItem] {
        checklistItems.filter { $0.category == .residence }
    }

    var presenceItems: [ComplianceChecklistItem] {
        checklistItems.filter { $0.category == .presence }
    }

    var tiesItems: [ComplianceChecklistItem] {
        checklistItems.filter { $0.category == .ties }
    }

    var financialItems: [ComplianceChecklistItem] {
        checklistItems.filter { $0.category == .financial }
    }

    var documentationItems: [ComplianceChecklistItem] {
        checklistItems.filter { $0.category == .documentation }
    }

    // MARK: - Formatted Values

    var formattedLastVisit: String {
        guard let date = lastVisitDate else {
            return "Never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var formattedComplianceScore: String {
        "\(complianceScore)%"
    }

    var thirtyDayStatusMessage: String {
        guard let days = daysUntil30DayReturn else {
            return "Schedule your first visit"
        }

        if days <= 0 {
            return "Overdue! Visit tax home immediately"
        } else if days <= 7 {
            return "\(days) days remaining - Schedule soon!"
        } else {
            return "\(days) days until required visit"
        }
    }

    var thirtyDayStatusColor: Color {
        guard let days = daysUntil30DayReturn else {
            return TNColors.textSecondary
        }

        if days <= 0 {
            return TNColors.error
        } else if days <= 7 {
            return TNColors.warning
        } else {
            return TNColors.success
        }
    }

    // MARK: - Private Properties

    private var modelContext: ModelContext?

    // MARK: - Public Methods

    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCompliance()
    }

    func loadCompliance() {
        guard let modelContext = modelContext else { return }

        isLoading = true
        errorMessage = nil

        let currentYear = Calendar.current.component(.year, from: Date())
        let descriptor = FetchDescriptor<TaxHomeCompliance>(
            predicate: #Predicate { compliance in
                compliance.taxYear == currentYear
            }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            if let existing = results.first {
                compliance = existing
            } else {
                // Create new compliance record for current year
                let newCompliance = TaxHomeCompliance(taxYear: currentYear)
                modelContext.insert(newCompliance)
                try modelContext.save()
                compliance = newCompliance
            }
        } catch {
            errorMessage = "Failed to load compliance data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() {
        loadCompliance()
    }

    func recordVisit(days: Int = 1) {
        guard let compliance = compliance else { return }

        compliance.recordTaxHomeVisit(days: days, date: Date())
        saveChanges()
    }

    func updateChecklistItem(_ itemId: String, status: ComplianceItemStatus) {
        guard let compliance = compliance else { return }

        var items = compliance.checklistItems
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].status = status
            items[index].lastUpdated = Date()
            compliance.checklistItems = items
            compliance.recalculateScore()
            saveChanges()
        }
    }

    func toggleItemStatus(_ item: ComplianceChecklistItem) {
        let newStatus: ComplianceItemStatus
        switch item.status {
        case .incomplete:
            newStatus = .complete
        case .complete:
            newStatus = .incomplete
        case .partial:
            newStatus = .complete
        case .notApplicable:
            newStatus = .incomplete
        }
        updateChecklistItem(item.id, status: newStatus)
    }

    // MARK: - Private Methods

    private func saveChanges() {
        guard let modelContext = modelContext else { return }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
    }
}
