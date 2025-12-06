//
//  ComplianceService.swift
//  TravelNurse
//
//  Service layer for Tax Home Compliance operations
//

import Foundation
import SwiftData

/// Protocol defining Compliance service operations
public protocol ComplianceServiceProtocol {
    func create(_ compliance: TaxHomeCompliance)
    func fetchAll() -> [TaxHomeCompliance]
    func fetch(byId id: UUID) -> TaxHomeCompliance?
    func fetch(forYear year: Int) -> TaxHomeCompliance?
    func fetchCurrent() -> TaxHomeCompliance?
    func getOrCreateCurrent() -> TaxHomeCompliance
    func update(_ compliance: TaxHomeCompliance)
    func delete(_ compliance: TaxHomeCompliance)
    func recordTaxHomeVisit(days: Int, date: Date)
    func updateChecklistItem(itemId: String, status: ComplianceItemStatus)
}

/// Service for managing Tax Home Compliance data operations
@MainActor
public final class ComplianceService: ComplianceServiceProtocol {

    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Creates a new compliance record
    public func create(_ compliance: TaxHomeCompliance) {
        compliance.updatedAt = Date()
        modelContext.insert(compliance)
        save()
    }

    /// Fetches all compliance records sorted by year (newest first)
    public func fetchAll() -> [TaxHomeCompliance] {
        let descriptor = FetchDescriptor<TaxHomeCompliance>(
            sortBy: [SortDescriptor(\.taxYear, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching compliance records: \(error)")
            return []
        }
    }

    /// Fetches a single compliance record by its unique ID
    public func fetch(byId id: UUID) -> TaxHomeCompliance? {
        let descriptor = FetchDescriptor<TaxHomeCompliance>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching compliance by ID: \(error)")
            return nil
        }
    }

    /// Fetches compliance record for a specific year
    public func fetch(forYear year: Int) -> TaxHomeCompliance? {
        let descriptor = FetchDescriptor<TaxHomeCompliance>(
            predicate: #Predicate { $0.taxYear == year }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching compliance for year: \(error)")
            return nil
        }
    }

    /// Fetches current year's compliance record
    public func fetchCurrent() -> TaxHomeCompliance? {
        let currentYear = Calendar.current.component(.year, from: Date())
        return fetch(forYear: currentYear)
    }

    /// Gets or creates the current year's compliance record
    public func getOrCreateCurrent() -> TaxHomeCompliance {
        if let existing = fetchCurrent() {
            return existing
        }

        let newCompliance = TaxHomeCompliance()
        create(newCompliance)
        return newCompliance
    }

    /// Updates an existing compliance record
    public func update(_ compliance: TaxHomeCompliance) {
        compliance.updatedAt = Date()
        compliance.recalculateScore()
        save()
    }

    /// Deletes a compliance record
    public func delete(_ compliance: TaxHomeCompliance) {
        modelContext.delete(compliance)
        save()
    }

    // MARK: - Compliance Actions

    /// Records a visit to tax home
    public func recordTaxHomeVisit(days: Int, date: Date = Date()) {
        let compliance = getOrCreateCurrent()
        compliance.recordTaxHomeVisit(days: days, date: date)
        save()
    }

    /// Updates a checklist item status
    public func updateChecklistItem(itemId: String, status: ComplianceItemStatus) {
        let compliance = getOrCreateCurrent()
        var items = compliance.checklistItems

        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].status = status
            items[index].lastUpdated = Date()
            compliance.checklistItems = items
            compliance.recalculateScore()
            save()
        }
    }

    /// Updates checklist item with notes
    public func updateChecklistItem(itemId: String, status: ComplianceItemStatus, notes: String?) {
        let compliance = getOrCreateCurrent()
        var items = compliance.checklistItems

        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].status = status
            items[index].notes = notes
            items[index].lastUpdated = Date()
            compliance.checklistItems = items
            compliance.recalculateScore()
            save()
        }
    }

    // MARK: - Compliance Status

    /// Gets current compliance score
    public func currentComplianceScore() -> Int {
        fetchCurrent()?.complianceScore ?? 0
    }

    /// Gets current compliance level
    public func currentComplianceLevel() -> ComplianceLevel {
        fetchCurrent()?.complianceLevel ?? .unknown
    }

    /// Checks if 30-day rule is at risk
    public func is30DayRuleAtRisk() -> Bool {
        fetchCurrent()?.thirtyDayRuleAtRisk ?? true
    }

    /// Gets days until next tax home visit required
    public func daysUntilRequiredVisit() -> Int? {
        fetchCurrent()?.daysUntil30DayReturn
    }

    /// Gets checklist completion percentage
    public func checklistProgress() -> Double {
        fetchCurrent()?.checklistCompletionPercentage ?? 0
    }

    /// Gets incomplete checklist items
    public func incompleteChecklistItems() -> [ComplianceChecklistItem] {
        guard let compliance = fetchCurrent() else { return [] }
        return compliance.checklistItems.filter { $0.status == .incomplete }
    }

    // MARK: - Private Helpers

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
