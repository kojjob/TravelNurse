//
//  ReportsViewModel.swift
//  TravelNurse
//
//  View model for tax reports and financial summaries
//

import Foundation
import SwiftUI

/// Export format options for tax reports
enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case csv = "CSV"
    case json = "JSON"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .pdf: return "doc.fill"
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        }
    }

    var description: String {
        switch self {
        case .pdf: return "Best for printing and sharing with your accountant"
        case .csv: return "Import into Excel or accounting software"
        case .json: return "For developers and data integration"
        }
    }
}

/// Data model for state-by-state earnings breakdown
struct StateBreakdown: Identifiable {
    var id: String { state.rawValue }
    let state: USState
    let earnings: Decimal
    let weeksWorked: Int
    let hasStateTax: Bool

    var formattedEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: earnings as NSDecimalNumber) ?? "$0"
    }
}

/// View model managing reports data and export functionality
@Observable
final class ReportsViewModel {

    // MARK: - Published Properties

    var isLoading = false
    var isExporting = false
    var selectedYear: Int = Calendar.current.component(.year, from: Date())

    var totalIncome: Decimal = 0
    var totalExpenses: Decimal = 0
    var totalMileageDeduction: Decimal = 0
    var totalMiles: Double = 0
    var stateBreakdowns: [StateBreakdown] = []

    // MARK: - Computed Properties

    var formattedTotalIncome: String {
        formatCurrency(totalIncome)
    }

    var formattedTotalExpenses: String {
        formatCurrency(totalExpenses)
    }

    var formattedMileageDeduction: String {
        formatCurrency(totalMileageDeduction)
    }

    var netIncome: Decimal {
        totalIncome - totalExpenses - totalMileageDeduction
    }

    var formattedNetIncome: String {
        formatCurrency(netIncome)
    }

    // MARK: - Dependencies

    private var assignmentService: AssignmentServiceProtocol? {
        ServiceContainer.shared.assignmentService
    }

    private var expenseService: ExpenseServiceProtocol? {
        ServiceContainer.shared.expenseService
    }

    private var mileageService: MileageServiceProtocol? {
        ServiceContainer.shared.mileageService
    }

    // MARK: - Public Methods

    func loadData(for year: Int) {
        selectedYear = year
        isLoading = true

        // Load assignments for the year
        let yearStart = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
        let yearEnd = Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31))!

        calculateIncome(from: yearStart, to: yearEnd)
        calculateExpenses(from: yearStart, to: yearEnd)
        calculateMileage(from: yearStart, to: yearEnd)
        calculateStateBreakdowns(from: yearStart, to: yearEnd)

        isLoading = false
    }

    func exportToCSV(year: Int) {
        // TODO: Implement CSV export
        print("Exporting to CSV for year: \(year)")
    }

    func generatePDFReport(year: Int) {
        // TODO: Implement PDF generation
        print("Generating PDF report for year: \(year)")
    }

    func shareReport(year: Int) {
        // TODO: Implement share functionality
        print("Sharing report for year: \(year)")
    }

    func exportReport(format: ExportFormat) async -> URL? {
        isExporting = true
        defer { isExporting = false }

        // Simulate export processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        switch format {
        case .pdf:
            return generatePDFURL()
        case .csv:
            return generateCSVURL()
        case .json:
            return generateJSONURL()
        }
    }

    private func generatePDFURL() -> URL? {
        // TODO: Implement actual PDF generation
        let documentsPath = FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("tax_report_\(selectedYear).pdf")
    }

    private func generateCSVURL() -> URL? {
        // TODO: Implement actual CSV generation
        let documentsPath = FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("tax_report_\(selectedYear).csv")
    }

    private func generateJSONURL() -> URL? {
        // TODO: Implement actual JSON generation
        let documentsPath = FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("tax_report_\(selectedYear).json")
    }

    // MARK: - Private Methods

    private func calculateIncome(from startDate: Date, to endDate: Date) {
        let assignments = assignmentService?.fetchAll() ?? []

        totalIncome = assignments
            .filter { assignment in
                // Check if assignment overlaps with the date range
                let assignmentEnd = assignment.endDate
                return assignment.startDate <= endDate && assignmentEnd >= startDate
            }
            .reduce(Decimal.zero) { sum, assignment in
                // Calculate weekly pay for weeks within the year
                guard let payBreakdown = assignment.payBreakdown else { return sum }

                let overlapStart = max(assignment.startDate, startDate)
                let overlapEnd = min(assignment.endDate, endDate)

                let weeks = Calendar.current.dateComponents([.weekOfYear], from: overlapStart, to: overlapEnd).weekOfYear ?? 0
                return sum + (payBreakdown.weeklyGross * Decimal(max(weeks, 0)))
            }
    }

    private func calculateExpenses(from startDate: Date, to endDate: Date) {
        let expenses = expenseService?.fetchAll() ?? []

        totalExpenses = expenses
            .filter { $0.date >= startDate && $0.date <= endDate && $0.isDeductible }
            .reduce(Decimal.zero) { sum, expense in
                sum + expense.amount
            }
    }

    private func calculateMileage(from startDate: Date, to endDate: Date) {
        let trips = mileageService?.fetchAll() ?? []

        let filteredTrips = trips.filter { $0.startTime >= startDate && $0.startTime <= endDate }

        totalMiles = filteredTrips.reduce(0.0) { sum, trip in
            sum + trip.distanceMiles
        }

        // 2024 IRS standard mileage rate: $0.67 per mile
        let mileageRate: Decimal = 0.67
        totalMileageDeduction = Decimal(totalMiles) * mileageRate
    }

    private func calculateStateBreakdowns(from startDate: Date, to endDate: Date) {
        let assignments = assignmentService?.fetchAll() ?? []

        // Group assignments by state
        var stateData: [USState: (earnings: Decimal, weeks: Int)] = [:]

        for assignment in assignments {
            guard let state = assignment.location?.state else { continue }

            // Check if assignment overlaps with the date range
            let assignmentEnd = assignment.endDate
            guard assignment.startDate <= endDate && assignmentEnd >= startDate else { continue }

            // Calculate weeks within the year
            let overlapStart = max(assignment.startDate, startDate)
            let overlapEnd = min(assignment.endDate, endDate)
            let weeks = max(0, Calendar.current.dateComponents([.weekOfYear], from: overlapStart, to: overlapEnd).weekOfYear ?? 0)

            let earnings = (assignment.payBreakdown?.weeklyGross ?? 0) * Decimal(weeks)

            if let existing = stateData[state] {
                stateData[state] = (existing.earnings + earnings, existing.weeks + weeks)
            } else {
                stateData[state] = (earnings, weeks)
            }
        }

        // Convert to StateBreakdown array and sort by earnings
        stateBreakdowns = stateData.map { state, data in
            StateBreakdown(
                state: state,
                earnings: data.earnings,
                weeksWorked: data.weeks,
                hasStateTax: state.hasIncomeTax
            )
        }
        .sorted { $0.earnings > $1.earnings }
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}
