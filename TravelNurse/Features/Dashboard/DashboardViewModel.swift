//
//  DashboardViewModel.swift
//  TravelNurse
//
//  ViewModel for the Dashboard feature with real service bindings
//

import Foundation
import SwiftUI

/// ViewModel for Dashboard, binding to real services
@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - Published State

    var isLoading = false
    var errorMessage: String?

    // MARK: - Dashboard Data

    private(set) var currentAssignment: Assignment?
    private(set) var complianceScore: Int = 0
    private(set) var complianceLevel: ComplianceLevel = .unknown
    private(set) var daysUntilVisit: Int?
    private(set) var totalMileage: Double = 0
    private(set) var totalMileageDeduction: Decimal = 0
    private(set) var recentExpenses: [Expense] = []
    private(set) var totalYTDExpenses: Decimal = 0
    private(set) var totalYTDEarnings: Decimal = 0
    private(set) var assignmentDaysRemaining: Int?

    // MARK: - Computed Properties

    var hasActiveAssignment: Bool {
        currentAssignment != nil
    }

    var assignmentProgress: Double {
        guard let assignment = currentAssignment else { return 0 }
        let total = assignment.endDate.timeIntervalSince(assignment.startDate)
        let elapsed = Date().timeIntervalSince(assignment.startDate)
        return min(max(elapsed / total, 0), 1)
    }

    var complianceStatusColor: Color {
        complianceLevel.color
    }

    var formattedMileageDeduction: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalMileageDeduction as NSDecimalNumber) ?? "$0.00"
    }

    var formattedYTDExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalYTDExpenses as NSDecimalNumber) ?? "$0.00"
    }

    var formattedYTDEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalYTDEarnings as NSDecimalNumber) ?? "$0.00"
    }

    // MARK: - Private Properties

    private var assignmentService: AssignmentService?
    private var expenseService: ExpenseService?
    private var complianceService: ComplianceService?
    private var mileageService: MileageService?

    // MARK: - Initialization

    init() {
        // Services will be configured when loadData is called
    }

    // MARK: - Data Loading

    /// Load all dashboard data from services
    func loadData() {
        isLoading = true
        errorMessage = nil

        configureServices()

        let currentYear = Calendar.current.component(.year, from: Date())

        // Load current assignment
        loadAssignmentData(year: currentYear)

        // Load compliance data
        loadComplianceData()

        // Load mileage data
        loadMileageData(year: currentYear)

        // Load expense data
        loadExpenseData(year: currentYear)

        isLoading = false
    }

    /// Refresh all dashboard data
    func refresh() {
        loadData()
    }

    // MARK: - Private Methods

    private func configureServices() {
        do {
            assignmentService = try ServiceContainer.shared.getAssignmentService()
            expenseService = try ServiceContainer.shared.getExpenseService()
            complianceService = try ServiceContainer.shared.getComplianceService()
            mileageService = try ServiceContainer.shared.getMileageService()
        } catch {
            errorMessage = "Failed to initialize services: \(error.localizedDescription)"
        }
    }

    private func loadAssignmentData(year: Int) {
        guard let service = assignmentService else { return }

        currentAssignment = service.fetchCurrentAssignment()
        totalYTDEarnings = service.totalEarnings(forYear: year)

        if let assignment = currentAssignment {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let endDate = calendar.startOfDay(for: assignment.endDate)
            let components = calendar.dateComponents([.day], from: today, to: endDate)
            assignmentDaysRemaining = max(components.day ?? 0, 0)
        } else {
            assignmentDaysRemaining = nil
        }
    }

    private func loadComplianceData() {
        guard let service = complianceService else { return }

        complianceScore = service.currentComplianceScore()
        complianceLevel = service.currentComplianceLevel()
        daysUntilVisit = service.daysUntilRequiredVisit()
    }

    private func loadMileageData(year: Int) {
        guard let service = mileageService else { return }

        totalMileage = service.totalMiles(forYear: year)
        totalMileageDeduction = service.totalDeduction(forYear: year)
    }

    private func loadExpenseData(year: Int) {
        guard let service = expenseService else { return }

        recentExpenses = service.fetchRecent(limit: 5)
        totalYTDExpenses = service.totalDeductible(forYear: year)
    }
}
