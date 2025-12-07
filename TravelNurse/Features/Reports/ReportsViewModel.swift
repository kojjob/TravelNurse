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
    case csv = "CSV Spreadsheet"
    case pdf = "PDF Document"
    case json = "JSON Data"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .csv:
            return "Best for importing into Excel, Google Sheets, or other spreadsheet apps"
        case .pdf:
            return "Professional formatted report ready for printing or sharing with your accountant"
        case .json:
            return "Raw data format for backup or integration with other apps"
        }
    }

    var iconName: String {
        switch self {
        case .csv:
            return "tablecells"
        case .pdf:
            return "doc.richtext"
        case .json:
            return "curlybraces"
        }
    }

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .json: return "json"
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
        TNFormatters.currencyWhole(earnings)
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

    /// Estimated federal tax liability (rough estimate at 22% bracket)
    var estimatedTax: Decimal {
        // Simplified estimate: 22% federal bracket for travel nurse income
        // This is a rough estimate - actual tax will depend on many factors
        let taxableIncome = netIncome
        guard taxableIncome > 0 else { return 0 }
        return taxableIncome * Decimal(0.22)
    }

    var formattedEstimatedTax: String {
        formatCurrency(estimatedTax)
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

    /// Export report in the specified format
    /// - Parameter format: The export format to use
    /// - Returns: URL to the exported file, or nil if export failed
    func exportReport(format: ExportFormat) async -> URL? {
        isExporting = true
        defer { isExporting = false }

        // Simulate export delay for UI feedback
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        let fileName = "TaxReport_\(selectedYear).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            switch format {
            case .csv:
                let csvContent = generateCSVContent()
                try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

            case .pdf:
                // For now, generate a simple text file as PDF generation requires more setup
                let pdfContent = generateTextReportContent()
                try pdfContent.write(to: tempURL, atomically: true, encoding: .utf8)

            case .json:
                let jsonContent = generateJSONContent()
                try jsonContent.write(to: tempURL, atomically: true, encoding: .utf8)
            }

            return tempURL
        } catch {
            print("Export failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Export Content Generation

    private func generateCSVContent() -> String {
        var csv = "Category,Amount\n"
        csv += "Total Income,\(totalIncome)\n"
        csv += "Total Expenses,\(totalExpenses)\n"
        csv += "Mileage Deduction,\(totalMileageDeduction)\n"
        csv += "Total Miles,\(totalMiles)\n"
        csv += "Net Income,\(netIncome)\n"
        csv += "\nState,Earnings,Weeks Worked,Has State Tax\n"
        for breakdown in stateBreakdowns {
            csv += "\(breakdown.state.rawValue),\(breakdown.earnings),\(breakdown.weeksWorked),\(breakdown.hasStateTax)\n"
        }
        return csv
    }

    private func generateTextReportContent() -> String {
        var report = "TAX REPORT - \(selectedYear)\n"
        report += "========================\n\n"
        report += "SUMMARY\n"
        report += "-------\n"
        report += "Total Income: \(formattedTotalIncome)\n"
        report += "Total Expenses: \(formattedTotalExpenses)\n"
        report += "Mileage Deduction: \(formattedMileageDeduction)\n"
        report += "Total Miles: \(Int(totalMiles))\n"
        report += "Net Income: \(formattedNetIncome)\n\n"
        report += "STATE BREAKDOWN\n"
        report += "---------------\n"
        for breakdown in stateBreakdowns {
            report += "\(breakdown.state.rawValue): \(breakdown.formattedEarnings) (\(breakdown.weeksWorked) weeks)\n"
        }
        return report
    }

    private func generateJSONContent() -> String {
        let data: [String: Any] = [
            "year": selectedYear,
            "totalIncome": "\(totalIncome)",
            "totalExpenses": "\(totalExpenses)",
            "mileageDeduction": "\(totalMileageDeduction)",
            "totalMiles": totalMiles,
            "netIncome": "\(netIncome)",
            "stateBreakdowns": stateBreakdowns.map { breakdown in
                [
                    "state": breakdown.state.rawValue,
                    "earnings": "\(breakdown.earnings)",
                    "weeksWorked": breakdown.weeksWorked,
                    "hasStateTax": breakdown.hasStateTax
                ]
            }
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }

    // MARK: - Private Methods

    private func calculateIncome(from startDate: Date, to endDate: Date) {
        let assignments = assignmentService?.fetchAllOrEmpty() ?? []

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
        let expenses = expenseService?.fetchAllOrEmpty() ?? []

        totalExpenses = expenses
            .filter { $0.date >= startDate && $0.date <= endDate && $0.isDeductible }
            .reduce(Decimal.zero) { sum, expense in
                sum + expense.amount
            }
    }

    private func calculateMileage(from startDate: Date, to endDate: Date) {
        let trips = mileageService?.fetchAllOrEmpty() ?? []

        let filteredTrips = trips.filter { $0.startTime >= startDate && $0.startTime <= endDate }

        totalMiles = filteredTrips.reduce(0.0) { sum, trip in
            sum + trip.distanceMiles
        }

        // 2024 IRS standard mileage rate: $0.67 per mile
        let mileageRate: Decimal = 0.67
        totalMileageDeduction = Decimal(totalMiles) * mileageRate
    }

    private func calculateStateBreakdowns(from startDate: Date, to endDate: Date) {
        let assignments = assignmentService?.fetchAllOrEmpty() ?? []

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
        TNFormatters.currencyWhole(value)
    }
}
