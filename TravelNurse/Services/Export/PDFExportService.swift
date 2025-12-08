//
//  PDFExportService.swift
//  TravelNurse
//
//  Professional PDF generation service for tax reports using PDFKit
//

import Foundation
import PDFKit
import UIKit

// MARK: - Data Models

/// Data model for generating tax report PDFs
public struct TaxReportData {
    public let year: Int
    public let userName: String
    public let totalIncome: Decimal
    public let totalExpenses: Decimal
    public let mileageDeduction: Decimal
    public let totalMiles: Double
    public let stateBreakdowns: [StateBreakdown]

    /// Net income after deductions
    public var netIncome: Decimal {
        totalIncome - totalExpenses - mileageDeduction
    }

    /// Estimated federal tax (simplified 22% bracket)
    public var estimatedTax: Decimal {
        let taxable = netIncome
        guard taxable > 0 else { return 0 }
        return taxable * Decimal(0.22)
    }

    public init(
        year: Int,
        userName: String,
        totalIncome: Decimal,
        totalExpenses: Decimal,
        mileageDeduction: Decimal,
        totalMiles: Double,
        stateBreakdowns: [StateBreakdown]
    ) {
        self.year = year
        self.userName = userName
        self.totalIncome = totalIncome
        self.totalExpenses = totalExpenses
        self.mileageDeduction = mileageDeduction
        self.totalMiles = totalMiles
        self.stateBreakdowns = stateBreakdowns
    }
}

// MARK: - PDF Export Service Protocol

/// Protocol for PDF export operations
public protocol PDFExportServiceProtocol {
    func generateTaxReport(from data: TaxReportData) async -> Data?
    func exportTaxReport(from data: TaxReportData, to url: URL) async -> Bool
}

// MARK: - PDF Export Service

/// Service for generating professional PDF tax reports
@MainActor
public final class PDFExportService: PDFExportServiceProtocol {

    // MARK: - Constants

    private enum Layout {
        static let pageWidth: CGFloat = 612  // Letter size width in points
        static let pageHeight: CGFloat = 792 // Letter size height in points
        static let margin: CGFloat = 50
        static let contentWidth: CGFloat = pageWidth - (margin * 2)
        static let lineSpacing: CGFloat = 6
        static let sectionSpacing: CGFloat = 24
        static let tableRowHeight: CGFloat = 24
    }

    private enum Colors {
        static let primary = UIColor(red: 0.0, green: 0.48, blue: 0.65, alpha: 1.0)  // Teal blue
        static let secondary = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Dark gray
        static let accent = UIColor(red: 0.0, green: 0.6, blue: 0.4, alpha: 1.0)     // Green
        static let lightGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        static let tableHeader = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    }

    private enum Fonts {
        static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let subtitle = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let sectionHeader = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let body = UIFont.systemFont(ofSize: 12, weight: .regular)
        static let bodyBold = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let tableHeader = UIFont.systemFont(ofSize: 11, weight: .bold)
        static let tableCell = UIFont.systemFont(ofSize: 11, weight: .regular)
        static let footer = UIFont.systemFont(ofSize: 9, weight: .regular)
        static let highlight = UIFont.systemFont(ofSize: 16, weight: .bold)
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Generate PDF data for a tax report
    public func generateTaxReport(from data: TaxReportData) async -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "TravelNurse App",
            kCGPDFContextAuthor: data.userName,
            kCGPDFContextTitle: "Tax Report \(data.year)"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: Layout.pageWidth, height: Layout.pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let pdfData = renderer.pdfData { context in
            context.beginPage()
            var yPosition = Layout.margin

            // Draw header
            yPosition = drawHeader(data: data, at: yPosition, in: context)
            yPosition += Layout.sectionSpacing

            // Draw financial summary
            yPosition = drawFinancialSummary(data: data, at: yPosition, in: context)
            yPosition += Layout.sectionSpacing

            // Draw deductions section
            yPosition = drawDeductionsSection(data: data, at: yPosition, in: context)
            yPosition += Layout.sectionSpacing

            // Check if we need a new page for state breakdown
            if yPosition > Layout.pageHeight - 250 {
                context.beginPage()
                yPosition = Layout.margin
            }

            // Draw state breakdown table
            yPosition = drawStateBreakdown(data: data, at: yPosition, in: context)
            yPosition += Layout.sectionSpacing

            // Draw tax summary
            yPosition = drawTaxSummary(data: data, at: yPosition, in: context)

            // Draw footer on each page
            drawFooter(data: data, in: context)
        }

        return pdfData
    }

    /// Export PDF to a file URL
    public func exportTaxReport(from data: TaxReportData, to url: URL) async -> Bool {
        guard let pdfData = await generateTaxReport(from: data) else {
            return false
        }

        do {
            try pdfData.write(to: url)
            return true
        } catch {
            ServiceLogger.log(
                "Failed to write PDF to file: \(error.localizedDescription)",
                category: .general,
                level: .error,
                error: error
            )
            return false
        }
    }

    // MARK: - Drawing Methods

    private func drawHeader(data: TaxReportData, at yPosition: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // App name / branding
        let brandText = "TravelNurse"
        let brandAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.subtitle,
            .foregroundColor: Colors.primary
        ]
        brandText.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: brandAttributes)
        y += 20

        // Main title
        let title = "Tax Report \(data.year)"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.title,
            .foregroundColor: Colors.secondary
        ]
        title.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: titleAttributes)
        y += 36

        // User name
        let userAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.subtitle,
            .foregroundColor: Colors.secondary
        ]
        data.userName.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: userAttributes)
        y += 18

        // Generation date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let generatedText = "Generated: \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: UIColor.gray
        ]
        generatedText.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: dateAttributes)
        y += 24

        // Divider line
        drawHorizontalLine(at: y, in: context, color: Colors.primary, thickness: 2)
        y += 8

        return y
    }

    private func drawFinancialSummary(data: TaxReportData, at yPosition: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        // Section header
        y = drawSectionHeader("Financial Summary", at: y)
        y += Layout.lineSpacing

        // Summary box background
        let boxRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 100)
        Colors.lightGray.setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 8).fill()

        y += 12

        // Financial metrics in a grid layout
        let columnWidth = Layout.contentWidth / 2 - 20
        let leftX = Layout.margin + 16
        let rightX = Layout.margin + Layout.contentWidth / 2 + 8

        // Left column
        y = drawMetricRow(label: "Total Income", value: formatCurrency(data.totalIncome), at: CGPoint(x: leftX, y: y), width: columnWidth, highlight: true)
        y = drawMetricRow(label: "Total Expenses", value: formatCurrency(data.totalExpenses), at: CGPoint(x: leftX, y: y), width: columnWidth)
        y = drawMetricRow(label: "Mileage Deduction", value: formatCurrency(data.mileageDeduction), at: CGPoint(x: leftX, y: y), width: columnWidth)

        // Reset y for right column
        y = yPosition + 12 + Layout.lineSpacing

        // Net income (highlight)
        let netIncomeY = drawMetricRow(label: "Net Income", value: formatCurrency(data.netIncome), at: CGPoint(x: rightX, y: y), width: columnWidth, highlight: true, color: Colors.accent)

        return max(yPosition + 112, netIncomeY + 16)
    }

    private func drawDeductionsSection(data: TaxReportData, at yPosition: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        y = drawSectionHeader("Deduction Details", at: y)
        y += Layout.lineSpacing

        // Mileage details
        let mileageText = "Business Miles Driven: \(Int(data.totalMiles).formatted()) miles"
        let mileageAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        mileageText.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: mileageAttributes)
        y += 18

        let rateText = "IRS Standard Mileage Rate: $0.67/mile (2024)"
        rateText.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: mileageAttributes)
        y += 18

        let totalMileageText = "Total Mileage Deduction: \(formatCurrency(data.mileageDeduction))"
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.bodyBold,
            .foregroundColor: Colors.secondary
        ]
        totalMileageText.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: boldAttributes)
        y += 24

        return y
    }

    private func drawStateBreakdown(data: TaxReportData, at yPosition: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        y = drawSectionHeader("State-by-State Breakdown", at: y)
        y += Layout.lineSpacing

        guard !data.stateBreakdowns.isEmpty else {
            let emptyText = "No state assignments recorded for this year."
            let emptyAttributes: [NSAttributedString.Key: Any] = [
                .font: Fonts.body,
                .foregroundColor: UIColor.gray
            ]
            emptyText.draw(at: CGPoint(x: Layout.margin, y: y), withAttributes: emptyAttributes)
            return y + 20
        }

        // Table header
        let headerRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: Layout.tableRowHeight)
        Colors.tableHeader.setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableHeader,
            .foregroundColor: UIColor.white
        ]

        let columns = [
            (text: "State", x: Layout.margin + 8, width: 120.0),
            (text: "Earnings", x: Layout.margin + 140, width: 120.0),
            (text: "Weeks", x: Layout.margin + 280, width: 80.0),
            (text: "State Tax", x: Layout.margin + 380, width: 100.0)
        ]

        for column in columns {
            column.text.draw(at: CGPoint(x: column.x, y: y + 6), withAttributes: headerAttributes)
        }
        y += Layout.tableRowHeight

        // Table rows
        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.tableCell,
            .foregroundColor: Colors.secondary
        ]

        for (index, breakdown) in data.stateBreakdowns.enumerated() {
            // Alternate row colors
            if index % 2 == 0 {
                let rowRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: Layout.tableRowHeight)
                Colors.lightGray.setFill()
                UIBezierPath(rect: rowRect).fill()
            }

            breakdown.state.fullName.draw(at: CGPoint(x: columns[0].x, y: y + 6), withAttributes: cellAttributes)
            formatCurrency(breakdown.earnings).draw(at: CGPoint(x: columns[1].x, y: y + 6), withAttributes: cellAttributes)
            "\(breakdown.weeksWorked)".draw(at: CGPoint(x: columns[2].x, y: y + 6), withAttributes: cellAttributes)

            let taxStatus = breakdown.hasStateTax ? "Yes" : "No"
            let taxColor = breakdown.hasStateTax ? UIColor.red : Colors.accent
            let taxAttributes: [NSAttributedString.Key: Any] = [
                .font: Fonts.tableCell,
                .foregroundColor: taxColor
            ]
            taxStatus.draw(at: CGPoint(x: columns[3].x, y: y + 6), withAttributes: taxAttributes)

            y += Layout.tableRowHeight
        }

        // Table border
        let tableRect = CGRect(x: Layout.margin, y: yPosition + Layout.lineSpacing + Layout.tableRowHeight,
                               width: Layout.contentWidth, height: y - (yPosition + Layout.lineSpacing + Layout.tableRowHeight))
        UIColor.lightGray.setStroke()
        UIBezierPath(rect: tableRect).stroke()

        return y + 8
    }

    private func drawTaxSummary(data: TaxReportData, at yPosition: CGFloat, in context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = yPosition

        y = drawSectionHeader("Estimated Tax Summary", at: y)
        y += Layout.lineSpacing

        // Summary box
        let boxRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 80)
        Colors.primary.withAlphaComponent(0.1).setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 8).fill()

        Colors.primary.setStroke()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 8).stroke()

        y += 12

        let taxableIncomeText = "Taxable Income (Net): \(formatCurrency(data.netIncome))"
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.body,
            .foregroundColor: Colors.secondary
        ]
        taxableIncomeText.draw(at: CGPoint(x: Layout.margin + 16, y: y), withAttributes: regularAttributes)
        y += 20

        let estimatedTaxText = "Estimated Federal Tax (22% bracket): \(formatCurrency(data.estimatedTax))"
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.highlight,
            .foregroundColor: Colors.primary
        ]
        estimatedTaxText.draw(at: CGPoint(x: Layout.margin + 16, y: y), withAttributes: highlightAttributes)
        y += 24

        // Disclaimer
        let disclaimerText = "* This is an estimate only. Consult a tax professional for accurate tax advice."
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.footer,
            .foregroundColor: UIColor.gray
        ]
        disclaimerText.draw(at: CGPoint(x: Layout.margin + 16, y: y), withAttributes: disclaimerAttributes)

        return y + 30
    }

    private func drawFooter(data: TaxReportData, in context: UIGraphicsPDFRendererContext) {
        let footerY = Layout.pageHeight - 40

        // Footer line
        drawHorizontalLine(at: footerY - 8, in: context, color: UIColor.lightGray, thickness: 0.5)

        // Footer text
        let footerText = "TravelNurse Tax Report | Generated on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.footer,
            .foregroundColor: UIColor.gray
        ]

        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerX = (Layout.pageWidth - footerSize.width) / 2
        footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)

        // Page number (for future multi-page support)
        let pageText = "Page 1"
        let pageX = Layout.pageWidth - Layout.margin - 30
        pageText.draw(at: CGPoint(x: pageX, y: footerY), withAttributes: footerAttributes)
    }

    // MARK: - Helper Methods

    private func drawSectionHeader(_ text: String, at yPosition: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.sectionHeader,
            .foregroundColor: Colors.primary
        ]
        text.draw(at: CGPoint(x: Layout.margin, y: yPosition), withAttributes: attributes)
        return yPosition + 24
    }

    private func drawMetricRow(label: String, value: String, at point: CGPoint, width: CGFloat, highlight: Bool = false, color: UIColor? = nil) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: highlight ? Fonts.bodyBold : Fonts.body,
            .foregroundColor: Colors.secondary
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: highlight ? Fonts.highlight : Fonts.bodyBold,
            .foregroundColor: color ?? Colors.secondary
        ]

        label.draw(at: point, withAttributes: labelAttributes)

        let valueSize = value.size(withAttributes: valueAttributes)
        let valueX = point.x + width - valueSize.width
        value.draw(at: CGPoint(x: valueX, y: point.y), withAttributes: valueAttributes)

        return point.y + (highlight ? 24 : 20)
    }

    private func drawHorizontalLine(at yPosition: CGFloat, in context: UIGraphicsPDFRendererContext, color: UIColor, thickness: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: Layout.margin, y: yPosition))
        path.addLine(to: CGPoint(x: Layout.pageWidth - Layout.margin, y: yPosition))
        path.lineWidth = thickness
        color.setStroke()
        path.stroke()
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
}
