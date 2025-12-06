//
//  ReportsViewModel.swift
//  TravelNurse
//
//  ViewModel for Reports & Export feature
//

import Foundation
import SwiftUI
import SwiftData
import PDFKit
import UIKit

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

    /// Available years for selection (last 6 years including current)
    private(set) var availableYears: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 5)...currentYear).reversed()
    }()

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

    nonisolated init(serviceContainer: ServiceContainer) {
        self.serviceContainer = serviceContainer
    }
    
    convenience init() {
        self.init(serviceContainer: .shared)
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
        // PDF page dimensions (US Letter size)
        let pageWidth: CGFloat = 612  // 8.5 inches at 72 dpi
        let pageHeight: CGFloat = 792 // 11 inches at 72 dpi
        let margin: CGFloat = 50

        // Colors
        let primaryColor = UIColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 1.0)
        let darkTextColor = UIColor(red: 0.067, green: 0.094, blue: 0.153, alpha: 1.0)
        let secondaryTextColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1.0)
        let successColor = UIColor(red: 0.063, green: 0.725, blue: 0.506, alpha: 1.0)

        // Fonts
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let headerFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let subheaderFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let captionFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let moneyFont = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Helper function to draw text
            func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, maxWidth: CGFloat? = nil) -> CGFloat {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                let textSize: CGSize

                if let maxWidth = maxWidth {
                    textSize = attributedString.boundingRect(
                        with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        context: nil
                    ).size
                    attributedString.draw(in: CGRect(x: point.x, y: point.y, width: maxWidth, height: textSize.height))
                } else {
                    textSize = attributedString.size()
                    attributedString.draw(at: point)
                }

                return textSize.height
            }

            // Helper function to draw a horizontal line
            func drawLine(at y: CGFloat, color: UIColor = .lightGray, width: CGFloat = 1) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                color.setStroke()
                path.lineWidth = width
                path.stroke()
            }

            // Helper function to draw a row with label and value
            func drawRow(label: String, value: String, at y: CGFloat, labelFont: UIFont = bodyFont, valueFont: UIFont = moneyFont) -> CGFloat {
                _ = drawText(label, at: CGPoint(x: margin, y: y), font: labelFont, color: secondaryTextColor)
                let valueWidth = (value as NSString).size(withAttributes: [.font: valueFont]).width
                _ = drawText(value, at: CGPoint(x: pageWidth - margin - valueWidth, y: y), font: valueFont, color: darkTextColor)
                return 22
            }

            // === HEADER ===
            // App name and logo area
            let appName = "TravelNurse"
            _ = drawText(appName, at: CGPoint(x: margin, y: yPosition), font: titleFont, color: primaryColor)
            yPosition += 35

            // Report title
            let reportTitle = "Tax Report - \(selectedYear)"
            _ = drawText(reportTitle, at: CGPoint(x: margin, y: yPosition), font: headerFont, color: darkTextColor)
            yPosition += 30

            // Generated date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let generatedText = "Generated: \(dateFormatter.string(from: Date()))"
            _ = drawText(generatedText, at: CGPoint(x: margin, y: yPosition), font: captionFont, color: secondaryTextColor)
            yPosition += 25

            drawLine(at: yPosition, color: primaryColor, width: 2)
            yPosition += 25

            // === ANNUAL SUMMARY SECTION ===
            _ = drawText("ANNUAL SUMMARY", at: CGPoint(x: margin, y: yPosition), font: headerFont, color: primaryColor)
            yPosition += 30

            // Summary rows
            yPosition += drawRow(label: "Total Gross Income", value: annualSummary.formattedGrossIncome, at: yPosition)
            yPosition += drawRow(label: "Total Taxable Income", value: annualSummary.formattedTaxableIncome, at: yPosition)
            yPosition += drawRow(label: "Total Stipends (Non-Taxable)", value: annualSummary.formattedStipends, at: yPosition)
            yPosition += 10

            drawLine(at: yPosition, color: .lightGray)
            yPosition += 15

            // Deductions section
            _ = drawText("Deductions", at: CGPoint(x: margin, y: yPosition), font: subheaderFont, color: darkTextColor)
            yPosition += 22

            yPosition += drawRow(label: "Business Expenses", value: annualSummary.formattedExpenses, at: yPosition)
            yPosition += drawRow(label: "Mileage Deduction", value: annualSummary.formattedMileageDeduction, at: yPosition)
            yPosition += 5

            // Total deductions with emphasis
            let totalDeductionsLabel = "Total Deductions"
            _ = drawText(totalDeductionsLabel, at: CGPoint(x: margin, y: yPosition), font: subheaderFont, color: successColor)
            let deductionValue = annualSummary.formattedTotalDeductions
            let deductionValueWidth = (deductionValue as NSString).size(withAttributes: [.font: moneyFont]).width
            _ = drawText(deductionValue, at: CGPoint(x: pageWidth - margin - deductionValueWidth, y: yPosition), font: moneyFont, color: successColor)
            yPosition += 30

            // Quick stats
            drawLine(at: yPosition, color: .lightGray)
            yPosition += 15

            let statsText = "\(annualSummary.totalAssignments) Assignments  •  \(annualSummary.statesWorkedIn) States  •  \(annualSummary.totalDaysWorked) Days Worked"
            _ = drawText(statsText, at: CGPoint(x: margin, y: yPosition), font: bodyFont, color: secondaryTextColor)
            yPosition += 35

            // === STATE-BY-STATE BREAKDOWN ===
            _ = drawText("STATE-BY-STATE BREAKDOWN", at: CGPoint(x: margin, y: yPosition), font: headerFont, color: primaryColor)
            yPosition += 25

            // Table header
            let stateColX = margin
            let daysColX = margin + 150
            let grossColX = margin + 220
            let taxableColX = margin + 320
            let stipendsColX = margin + 420

            _ = drawText("State", at: CGPoint(x: stateColX, y: yPosition), font: captionFont, color: secondaryTextColor)
            _ = drawText("Days", at: CGPoint(x: daysColX, y: yPosition), font: captionFont, color: secondaryTextColor)
            _ = drawText("Gross", at: CGPoint(x: grossColX, y: yPosition), font: captionFont, color: secondaryTextColor)
            _ = drawText("Taxable", at: CGPoint(x: taxableColX, y: yPosition), font: captionFont, color: secondaryTextColor)
            _ = drawText("Stipends", at: CGPoint(x: stipendsColX, y: yPosition), font: captionFont, color: secondaryTextColor)
            yPosition += 18

            drawLine(at: yPosition, color: .lightGray)
            yPosition += 10

            for summary in sortedStateSummaries {
                // Check if we need a new page
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = margin
                }

                let stateName = "\(summary.state.fullName) (\(summary.state.rawValue))"
                _ = drawText(stateName, at: CGPoint(x: stateColX, y: yPosition), font: bodyFont, color: darkTextColor)
                _ = drawText("\(summary.daysWorked)", at: CGPoint(x: daysColX, y: yPosition), font: bodyFont, color: darkTextColor)
                _ = drawText(summary.formattedGrossIncome, at: CGPoint(x: grossColX, y: yPosition), font: bodyFont, color: darkTextColor)
                _ = drawText(summary.formattedTaxableIncome, at: CGPoint(x: taxableColX, y: yPosition), font: bodyFont, color: darkTextColor)
                _ = drawText(summary.formattedStipends, at: CGPoint(x: stipendsColX, y: yPosition), font: bodyFont, color: darkTextColor)
                yPosition += 20
            }

            yPosition += 25

            // === EXPENSE BREAKDOWN ===
            // Check if we need a new page
            if yPosition > pageHeight - 150 {
                context.beginPage()
                yPosition = margin
            }

            _ = drawText("EXPENSE BREAKDOWN BY CATEGORY", at: CGPoint(x: margin, y: yPosition), font: headerFont, color: primaryColor)
            yPosition += 25

            let sortedExpenses = expensesByCategory.sorted { $0.value > $1.value }

            if sortedExpenses.isEmpty {
                _ = drawText("No expenses recorded for this year", at: CGPoint(x: margin, y: yPosition), font: bodyFont, color: secondaryTextColor)
                yPosition += 25
            } else {
                for (category, amount) in sortedExpenses {
                    // Check if we need a new page
                    if yPosition > pageHeight - 60 {
                        context.beginPage()
                        yPosition = margin
                    }

                    yPosition += drawRow(label: category.displayName, value: formatCurrency(amount), at: yPosition)
                }
            }

            // === FOOTER ===
            // Draw footer at bottom of last page
            let footerY = pageHeight - 40
            drawLine(at: footerY - 10, color: .lightGray)

            let footerText = "TravelNurse Tax Companion • This report is for informational purposes only. Consult a tax professional for advice."
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: secondaryTextColor
            ]
            let footerSize = (footerText as NSString).size(withAttributes: footerAttributes)
            let footerX = (pageWidth - footerSize.width) / 2
            (footerText as NSString).draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
        }

        // Write PDF data to file
        let fileName = "TravelNurse_TaxReport_\(selectedYear).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)

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
