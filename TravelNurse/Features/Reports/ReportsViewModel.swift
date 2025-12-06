//
//  ReportsViewModel.swift
//  TravelNurse
//
//  ViewModel for Reports & Export feature
//

import Foundation
import SwiftUI
import SwiftData

/// Data structure for state-level tax summary
struct StateTaxSummary: Identifiable, Hashable {
    let id = UUID()
    let state: USState
    let daysWorked: Int
    let grossIncome: Decimal
    let taxableIncome: Decimal
    let stipends: Decimal
    let expenses: Decimal
    let assignments: [Assignment]

    var formattedGrossIncome: String {
        formatCurrency(grossIncome)
    }

    var formattedTaxableIncome: String {
        formatCurrency(taxableIncome)
    }

    var formattedStipends: String {
        formatCurrency(stipends)
    }

    var formattedExpenses: String {
        formatCurrency(expenses)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
}

/// Data structure for annual summary
struct AnnualSummary {
    let year: Int
    let totalGrossIncome: Decimal
    let totalTaxableIncome: Decimal
    let totalStipends: Decimal
    let totalExpenses: Decimal
    let totalMileageDeduction: Decimal
    let totalAssignments: Int
    let statesWorkedIn: Int
    let totalDaysWorked: Int

    var formattedGrossIncome: String {
        formatCurrency(totalGrossIncome)
    }

    var formattedTaxableIncome: String {
        formatCurrency(totalTaxableIncome)
    }

    var formattedStipends: String {
        formatCurrency(totalStipends)
    }

    var formattedExpenses: String {
        formatCurrency(totalExpenses)
    }

    var formattedMileageDeduction: String {
        formatCurrency(totalMileageDeduction)
    }

    var totalDeductions: Decimal {
        totalExpenses + totalMileageDeduction
    }

    var formattedTotalDeductions: String {
        formatCurrency(totalDeductions)
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }

    static var empty: AnnualSummary {
        AnnualSummary(
            year: Calendar.current.component(.year, from: Date()),
            totalGrossIncome: 0,
            totalTaxableIncome: 0,
            totalStipends: 0,
            totalExpenses: 0,
            totalMileageDeduction: 0,
            totalAssignments: 0,
            statesWorkedIn: 0,
            totalDaysWorked: 0
        )
    }
}

/// Export format options
enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case pdf = "PDF"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        }
    }

    var description: String {
        switch self {
        case .csv: return "Spreadsheet format, compatible with Excel and tax software"
        case .pdf: return "Professional document for record-keeping"
        }
    }
}

/// ViewModel managing Reports & Export state and business logic
@MainActor
@Observable
final class ReportsViewModel {

    // MARK: - State

    /// Selected tax year
    var selectedYear: Int = Calendar.current.component(.year, from: Date())

    /// Available years for selection
    private(set) var availableYears: [Int] = []

    /// Annual summary data
    private(set) var annualSummary: AnnualSummary = .empty

    /// State-level summaries
    private(set) var stateSummaries: [StateTaxSummary] = []

    /// Expense breakdown by category
    private(set) var expensesByCategory: [ExpenseCategory: Decimal] = [:]

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Whether to show error alert
    var showError = false

    /// Whether to show export sheet
    var showExportSheet = false

    /// Whether export is in progress
    private(set) var isExporting = false

    /// Export success message
    private(set) var exportSuccessMessage: String?

    /// Whether to show export success
    var showExportSuccess = false

    // MARK: - Dependencies

    private let serviceContainer: ServiceContainer

    // MARK: - Computed Properties

    /// Sorted state summaries by income (highest first)
    var sortedStateSummaries: [StateTaxSummary] {
        stateSummaries.sorted { $0.grossIncome > $1.grossIncome }
    }

    /// Top expense categories
    var topExpenseCategories: [(category: ExpenseCategory, amount: Decimal)] {
        expensesByCategory
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (category: $0.key, amount: $0.value) }
    }

    /// Format currency helper
    func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }

    // MARK: - Initialization

    init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
        setupAvailableYears()
    }

    // MARK: - Actions

    /// Load reports data for selected year
    func loadReports() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load assignments for the year
            let assignments = try loadAssignments(for: selectedYear)

            // Load expenses for the year
            let expenses = try loadExpenses(for: selectedYear)

            // Load mileage trips for the year
            let mileageTrips = try loadMileageTrips(for: selectedYear)

            // Calculate annual summary
            annualSummary = calculateAnnualSummary(
                assignments: assignments,
                expenses: expenses,
                mileageTrips: mileageTrips
            )

            // Calculate state summaries
            stateSummaries = calculateStateSummaries(assignments: assignments)

            // Calculate expense breakdown
            expensesByCategory = calculateExpenseBreakdown(expenses: expenses)

        } catch {
            errorMessage = "Failed to load reports: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    /// Change selected year and reload
    func selectYear(_ year: Int) async {
        selectedYear = year
        await loadReports()
    }

    /// Export report in specified format
    func exportReport(format: ExportFormat) async -> URL? {
        isExporting = true
        defer { isExporting = false }

        do {
            let url: URL

            switch format {
            case .csv:
                url = try generateCSVReport()
            case .pdf:
                url = try generatePDFReport()
            }

            exportSuccessMessage = "\(format.rawValue) report exported successfully"
            showExportSuccess = true

            return url
        } catch {
            errorMessage = "Failed to export report: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    /// Dismiss export success
    func dismissExportSuccess() {
        showExportSuccess = false
        exportSuccessMessage = nil
    }

    // MARK: - Private Methods

    private func setupAvailableYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        availableYears = Array((currentYear - 5)...currentYear).reversed()
    }

    private func loadAssignments(for year: Int) throws -> [Assignment] {
        let service = try serviceContainer.getAssignmentService()
        return service.fetch(byYear: year)
    }

    private func loadExpenses(for year: Int) throws -> [Expense] {
        let service = try serviceContainer.getExpenseService()
        return service.fetch(byYear: year)
    }

    private func loadMileageTrips(for year: Int) throws -> [MileageTrip] {
        let service = try serviceContainer.getMileageService()
        return service.fetch(byYear: year)
    }

    private func calculateAnnualSummary(
        assignments: [Assignment],
        expenses: [Expense],
        mileageTrips: [MileageTrip]
    ) -> AnnualSummary {
        // Calculate totals from assignments
        var totalGross: Decimal = 0
        var totalTaxable: Decimal = 0
        var totalStipends: Decimal = 0
        var totalDays = 0
        var statesSet = Set<USState>()

        for assignment in assignments {
            if let pay = assignment.payBreakdown {
                let weeks = Decimal(assignment.durationWeeks)
                totalGross += pay.weeklyGross * weeks
                totalTaxable += pay.weeklyTaxable * weeks
                totalStipends += pay.weeklyStipends * weeks
            }
            totalDays += assignment.durationDays
            if let state = assignment.state {
                statesSet.insert(state)
            }
        }

        // Calculate expense total
        let totalExpenses = expenses
            .filter { $0.isDeductible }
            .reduce(Decimal(0)) { $0 + $1.amount }

        // Calculate mileage deduction
        let totalMileage = mileageTrips.reduce(Decimal(0)) { $0 + $1.deductionAmount }

        return AnnualSummary(
            year: selectedYear,
            totalGrossIncome: totalGross,
            totalTaxableIncome: totalTaxable,
            totalStipends: totalStipends,
            totalExpenses: totalExpenses,
            totalMileageDeduction: totalMileage,
            totalAssignments: assignments.count,
            statesWorkedIn: statesSet.count,
            totalDaysWorked: totalDays
        )
    }

    private func calculateStateSummaries(assignments: [Assignment]) -> [StateTaxSummary] {
        // Group assignments by state
        var stateAssignments: [USState: [Assignment]] = [:]

        for assignment in assignments {
            guard let state = assignment.state else { continue }
            stateAssignments[state, default: []].append(assignment)
        }

        // Create summaries for each state
        return stateAssignments.map { state, assignments in
            var gross: Decimal = 0
            var taxable: Decimal = 0
            var stipends: Decimal = 0
            var days = 0

            for assignment in assignments {
                if let pay = assignment.payBreakdown {
                    let weeks = Decimal(assignment.durationWeeks)
                    gross += pay.weeklyGross * weeks
                    taxable += pay.weeklyTaxable * weeks
                    stipends += pay.weeklyStipends * weeks
                }
                days += assignment.durationDays
            }

            return StateTaxSummary(
                state: state,
                daysWorked: days,
                grossIncome: gross,
                taxableIncome: taxable,
                stipends: stipends,
                expenses: 0, // Would need state-specific expense tracking
                assignments: assignments
            )
        }
    }

    private func calculateExpenseBreakdown(expenses: [Expense]) -> [ExpenseCategory: Decimal] {
        var breakdown: [ExpenseCategory: Decimal] = [:]

        for expense in expenses where expense.isDeductible {
            breakdown[expense.category, default: 0] += expense.amount
        }

        return breakdown
    }

    // MARK: - Export Generation

    private func generateCSVReport() throws -> URL {
        var csvContent = "TravelNurse Tax Report - \(selectedYear)\n\n"

        // Annual Summary
        csvContent += "ANNUAL SUMMARY\n"
        csvContent += "Total Gross Income,\(annualSummary.formattedGrossIncome)\n"
        csvContent += "Total Taxable Income,\(annualSummary.formattedTaxableIncome)\n"
        csvContent += "Total Stipends,\(annualSummary.formattedStipends)\n"
        csvContent += "Total Expenses,\(annualSummary.formattedExpenses)\n"
        csvContent += "Mileage Deduction,\(annualSummary.formattedMileageDeduction)\n"
        csvContent += "Total Deductions,\(annualSummary.formattedTotalDeductions)\n"
        csvContent += "Assignments,\(annualSummary.totalAssignments)\n"
        csvContent += "States Worked,\(annualSummary.statesWorkedIn)\n"
        csvContent += "Days Worked,\(annualSummary.totalDaysWorked)\n\n"

        // State Breakdown
        csvContent += "STATE BREAKDOWN\n"
        csvContent += "State,Days Worked,Gross Income,Taxable Income,Stipends\n"
        for summary in sortedStateSummaries {
            csvContent += "\(summary.state.fullName),\(summary.daysWorked),\(summary.formattedGrossIncome),\(summary.formattedTaxableIncome),\(summary.formattedStipends)\n"
        }
        csvContent += "\n"

        // Expense Breakdown
        csvContent += "EXPENSE BREAKDOWN\n"
        csvContent += "Category,Amount\n"
        for (category, amount) in expensesByCategory.sorted(by: { $0.value > $1.value }) {
            csvContent += "\(category.displayName),\(formatCurrency(amount))\n"
        }

        // Write to temp file
        let fileName = "TravelNurse_TaxReport_\(selectedYear).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

        return tempURL
    }

    private func generatePDFReport() throws -> URL {
        // For MVP, generate a text-based PDF-ready content
        // In production, would use PDFKit or similar for proper PDF generation
        var content = """
        ══════════════════════════════════════════════════
        TRAVELNURSE TAX REPORT - \(selectedYear)
        ══════════════════════════════════════════════════

        ANNUAL SUMMARY
        ──────────────────────────────────────────────────
        Total Gross Income:     \(annualSummary.formattedGrossIncome)
        Total Taxable Income:   \(annualSummary.formattedTaxableIncome)
        Total Stipends:         \(annualSummary.formattedStipends)
        Total Expenses:         \(annualSummary.formattedExpenses)
        Mileage Deduction:      \(annualSummary.formattedMileageDeduction)
        ──────────────────────────────────────────────────
        Total Deductions:       \(annualSummary.formattedTotalDeductions)

        ASSIGNMENTS: \(annualSummary.totalAssignments)
        STATES WORKED: \(annualSummary.statesWorkedIn)
        DAYS WORKED: \(annualSummary.totalDaysWorked)

        STATE-BY-STATE BREAKDOWN
        ──────────────────────────────────────────────────
        """

        for summary in sortedStateSummaries {
            content += """

            \(summary.state.fullName) (\(summary.state.rawValue))
              Days: \(summary.daysWorked)
              Gross: \(summary.formattedGrossIncome)
              Taxable: \(summary.formattedTaxableIncome)
              Stipends: \(summary.formattedStipends)
            """
        }

        content += """


        EXPENSE CATEGORIES
        ──────────────────────────────────────────────────
        """

        for (category, amount) in expensesByCategory.sorted(by: { $0.value > $1.value }) {
            content += "\n  \(category.displayName): \(formatCurrency(amount))"
        }

        content += """


        ══════════════════════════════════════════════════
        Generated by TravelNurse App
        Report Date: \(Date().formatted(date: .long, time: .shortened))
        ══════════════════════════════════════════════════
        """

        // Write to temp file (as .txt for MVP, would be proper PDF in production)
        let fileName = "TravelNurse_TaxReport_\(selectedYear).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: tempURL, atomically: true, encoding: .utf8)

        return tempURL
    }
}

// MARK: - Preview Helper

extension ReportsViewModel {
    /// Create a preview instance with mock data
    static var preview: ReportsViewModel {
        let viewModel = ReportsViewModel()
        // Preview will load data when view appears
        return viewModel
    }
}
