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
public struct StateBreakdown: Identifiable {
    public var id: String { state.rawValue }
    public let state: USState
    public let earnings: Decimal
    public let weeksWorked: Int
    public let hasStateTax: Bool

    public var formattedEarnings: String {
        TNFormatters.currencyWhole(earnings)
    }

    public init(state: USState, earnings: Decimal, weeksWorked: Int, hasStateTax: Bool) {
        self.state = state
        self.earnings = earnings
        self.weeksWorked = weeksWorked
        self.hasStateTax = hasStateTax
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

    /// Cached tax calculation result for display and export
    private var cachedTaxResult: TaxCalculationResult?

    /// Estimated federal + state + self-employment tax liability using real tax brackets
    var estimatedTax: Decimal {
        // Use TaxCalculationService for accurate progressive bracket calculations
        if let taxService = ServiceContainer.shared.taxCalculationService {
            let taxHomeState = getUserTaxHomeState()
            let result = taxService.calculateTotalTax(
                grossIncome: totalIncome,
                deductions: totalExpenses + totalMileageDeduction,
                state: taxHomeState,
                isSelfEmployed: true // Travel nurses typically file as self-employed
            )
            cachedTaxResult = result
            return result.totalTax
        }

        // Fallback to simplified calculation if service unavailable
        let taxableIncome = netIncome
        guard taxableIncome > 0 else { return 0 }
        return taxableIncome * Decimal(0.22)
    }

    /// Effective tax rate based on calculated taxes
    var effectiveTaxRate: Double {
        guard let result = cachedTaxResult else {
            return totalIncome > 0 ? 0.22 : 0
        }
        return result.effectiveTaxRate
    }

    /// Get user's tax home state, defaulting to Texas (no state tax) if not set
    private func getUserTaxHomeState() -> USState {
        // TODO: In future, get from UserProfile.taxHomeState via userService
        // For now, default to Texas (no state income tax)
        // This is a safe default as Texas has no state income tax
        return .texas
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

    /// Export data to CSV format
    /// - Parameter year: The tax year to export
    /// - Returns: URL to the exported CSV file, or nil if export failed
    func exportToCSV(year: Int) async -> URL? {
        loadData(for: year)
        return await exportReport(format: .csv)
    }

    /// Generate PDF report
    /// - Parameter year: The tax year to generate report for
    /// - Returns: URL to the generated PDF file, or nil if generation failed
    func generatePDFReport(year: Int) async -> URL? {
        loadData(for: year)
        return await exportReport(format: .pdf)
    }

    /// Export data to JSON format for backup/integration
    /// - Parameter year: The tax year to export
    /// - Returns: URL to the exported JSON file, or nil if export failed
    func exportToJSON(year: Int) async -> URL? {
        loadData(for: year)
        return await exportReport(format: .json)
    }

    /// Share report via system share sheet
    /// - Parameter year: The tax year to share
    /// - Returns: URL to share, or nil if preparation failed
    func shareReport(year: Int) async -> URL? {
        loadData(for: year)
        // Default to PDF for sharing as it's most universally viewable
        return await exportReport(format: .pdf)
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
                // Generate professional PDF using PDFExportService
                let reportData = createTaxReportData()
                let pdfService = PDFExportService()
                guard await pdfService.exportTaxReport(from: reportData, to: tempURL) else {
                    return nil
                }

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
        var csv = "TravelNurse Tax Report - \(selectedYear)\n"
        csv += "Generated: \(ISO8601DateFormatter().string(from: Date()))\n\n"

        // Summary Section
        csv += "SUMMARY\n"
        csv += "Category,Amount\n"
        csv += "Total Income,\(totalIncome)\n"
        csv += "Total Expenses,\(totalExpenses)\n"
        csv += "Mileage Deduction,\(totalMileageDeduction)\n"
        csv += "Total Miles,\(totalMiles)\n"
        csv += "Total Deductions,\(totalExpenses + totalMileageDeduction)\n"
        csv += "Net Income,\(netIncome)\n\n"

        // Tax Breakdown Section
        csv += "TAX BREAKDOWN\n"
        csv += "Tax Type,Amount\n"
        csv += "Federal Income Tax,\(cachedTaxResult?.federalTax ?? 0)\n"
        csv += "State Income Tax,\(cachedTaxResult?.stateTax ?? 0)\n"
        csv += "Self-Employment Tax,\(cachedTaxResult?.selfEmploymentTax ?? 0)\n"
        csv += "Total Estimated Tax,\(estimatedTax)\n"
        csv += "Effective Tax Rate,\(String(format: "%.1f%%", effectiveTaxRate * 100))\n"
        csv += "Marginal Tax Rate,\(cachedTaxResult?.marginalTaxRate ?? 0)\n\n"

        // State Breakdown Section
        csv += "STATE BREAKDOWN\n"
        csv += "State,Earnings,Weeks Worked,Has State Tax\n"
        for breakdown in stateBreakdowns {
            csv += "\(breakdown.state.rawValue),\(breakdown.earnings),\(breakdown.weeksWorked),\(breakdown.hasStateTax)\n"
        }

        // Expense Details Section
        csv += "\nEXPENSE DETAILS\n"
        csv += "Date,Category,Amount,Deductible,Notes\n"
        let expenses = expenseService?.fetchAllOrEmpty() ?? []
        let yearStart = Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let yearEnd = Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        let filteredExpenses = expenses.filter { $0.date >= yearStart && $0.date <= yearEnd }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for expense in filteredExpenses.sorted(by: { $0.date < $1.date }) {
            let notes = expense.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            csv += "\(dateFormatter.string(from: expense.date)),\(expense.category.displayName),\(expense.amount),\(expense.isDeductible),\"\(notes)\"\n"
        }

        // Mileage Details Section
        csv += "\nMILEAGE DETAILS\n"
        csv += "Date,Distance (miles),Trip Type,Deduction Amount\n"
        let trips = mileageService?.fetchAllOrEmpty() ?? []
        let filteredTrips = trips.filter { $0.startTime >= yearStart && $0.startTime <= yearEnd }

        for trip in filteredTrips.sorted(by: { $0.startTime < $1.startTime }) {
            csv += "\(dateFormatter.string(from: trip.startTime)),\(String(format: "%.1f", trip.distanceMiles)),\(trip.tripType.rawValue),\(trip.deductionAmount)\n"
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
        let dateFormatter = ISO8601DateFormatter()
        let yearStart = Calendar.current.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let yearEnd = Calendar.current.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!

        // Get expense details
        let expenses = expenseService?.fetchAllOrEmpty() ?? []
        let filteredExpenses = expenses.filter { $0.date >= yearStart && $0.date <= yearEnd }
        let expenseData: [[String: Any]] = filteredExpenses.map { expense in
            [
                "id": expense.id.uuidString,
                "date": dateFormatter.string(from: expense.date),
                "category": expense.category.rawValue,
                "categoryDisplayName": expense.category.displayName,
                "amount": "\(expense.amount)",
                "isDeductible": expense.isDeductible,
                "notes": expense.notes ?? ""
            ]
        }

        // Get mileage details
        let trips = mileageService?.fetchAllOrEmpty() ?? []
        let filteredTrips = trips.filter { $0.startTime >= yearStart && $0.startTime <= yearEnd }
        let mileageData: [[String: Any]] = filteredTrips.map { trip in
            [
                "id": trip.id.uuidString,
                "date": dateFormatter.string(from: trip.startTime),
                "distanceMiles": trip.distanceMiles,
                "tripType": trip.tripType.rawValue,
                "deductionAmount": "\(trip.deductionAmount)",
                "startLocation": trip.startLocationName,
                "endLocation": trip.endLocationName
            ]
        }

        let data: [String: Any] = [
            "exportInfo": [
                "appName": "TravelNurse",
                "exportDate": dateFormatter.string(from: Date()),
                "version": "1.0"
            ],
            "taxYear": selectedYear,
            "summary": [
                "totalIncome": "\(totalIncome)",
                "totalExpenses": "\(totalExpenses)",
                "mileageDeduction": "\(totalMileageDeduction)",
                "totalMiles": totalMiles,
                "totalDeductions": "\(totalExpenses + totalMileageDeduction)",
                "netIncome": "\(netIncome)",
                "estimatedTax": "\(estimatedTax)",
                "federalTax": "\(cachedTaxResult?.federalTax ?? 0)",
                "stateTax": "\(cachedTaxResult?.stateTax ?? 0)",
                "selfEmploymentTax": "\(cachedTaxResult?.selfEmploymentTax ?? 0)",
                "effectiveTaxRate": String(format: "%.1f%%", effectiveTaxRate * 100),
                "marginalTaxRate": "\(cachedTaxResult?.marginalTaxRate ?? 0)"
            ],
            "stateBreakdowns": stateBreakdowns.map { breakdown in
                [
                    "state": breakdown.state.rawValue,
                    "stateName": breakdown.state.fullName,
                    "earnings": "\(breakdown.earnings)",
                    "weeksWorked": breakdown.weeksWorked,
                    "hasStateTax": breakdown.hasStateTax
                ]
            },
            "expenses": expenseData,
            "mileageTrips": mileageData
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }

    /// Creates TaxReportData for PDF generation from current ViewModel state
    private func createTaxReportData() -> TaxReportData {
        TaxReportData(
            year: selectedYear,
            userName: "Travel Nurse", // TODO: Get from user profile when available
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            mileageDeduction: totalMileageDeduction,
            totalMiles: totalMiles,
            stateBreakdowns: stateBreakdowns
        )
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
