//
//  TaxesViewModel.swift
//  TravelNurse
//
//  ViewModel for the Taxes tab - quarterly tax tracking and estimates
//

import Foundation
import SwiftUI

/// Represents a quarterly tax payment with status tracking
struct QuarterlyTax: Identifiable {
    let id = UUID()
    let quarter: String
    let year: Int
    let dueDate: Date
    let estimatedAmount: Decimal
    var paidAmount: Decimal
    var isPaid: Bool
    var paidDate: Date?

    var formattedEstimatedAmount: String {
        formatCurrency(estimatedAmount)
    }

    var formattedPaidAmount: String {
        formatCurrency(paidAmount)
    }

    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: dueDate)
    }

    var remainingAmount: Decimal {
        max(0, estimatedAmount - paidAmount)
    }

    var formattedRemainingAmount: String {
        formatCurrency(remainingAmount)
    }

    var status: QuarterStatus {
        if isPaid { return .paid }
        if Date() > dueDate { return .overdue }
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        if daysUntilDue <= 30 { return .dueSoon }
        return .upcoming
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

enum QuarterStatus {
    case paid
    case overdue
    case dueSoon
    case upcoming

    var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .dueSoon: return "Due Soon"
        case .upcoming: return "Upcoming"
        }
    }

    var color: Color {
        switch self {
        case .paid: return TNColors.success
        case .overdue: return TNColors.error
        case .dueSoon: return TNColors.warning
        case .upcoming: return TNColors.textSecondary
        }
    }

    var iconName: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .upcoming: return "calendar"
        }
    }
}

/// Tax breakdown by category
struct TaxBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let amount: Decimal
    let percentage: Double
    let color: Color

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "$0"
    }
}

/// ViewModel managing Taxes tab state and business logic
@MainActor
@Observable
final class TaxesViewModel {

    // MARK: - State

    /// Selected tax year
    var selectedYear: Int = Calendar.current.component(.year, from: Date())

    /// Available years for selection
    private(set) var availableYears: [Int] = []

    /// Quarterly tax data
    private(set) var quarterlyTaxes: [QuarterlyTax] = []

    /// Tax breakdown by category
    private(set) var taxBreakdown: [TaxBreakdown] = []

    /// Total estimated tax for the year
    private(set) var totalEstimatedTax: Decimal = 0

    /// Total paid tax for the year
    private(set) var totalPaidTax: Decimal = 0

    /// YTD taxable income
    private(set) var ytdTaxableIncome: Decimal = 0

    /// YTD deductions
    private(set) var ytdDeductions: Decimal = 0

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Show error alert
    var showError = false

    /// Show payment sheet
    var showPaymentSheet = false

    /// Selected quarter for payment
    var selectedQuarterForPayment: QuarterlyTax?

    // MARK: - Dependencies

    private let serviceContainer: ServiceContainer

    // MARK: - Computed Properties

    /// Remaining tax to pay this year
    var remainingTax: Decimal {
        max(0, totalEstimatedTax - totalPaidTax)
    }

    /// Formatted remaining tax
    var formattedRemainingTax: String {
        formatCurrency(remainingTax)
    }

    /// Formatted total estimated tax
    var formattedTotalEstimatedTax: String {
        formatCurrency(totalEstimatedTax)
    }

    /// Formatted total paid tax
    var formattedTotalPaidTax: String {
        formatCurrency(totalPaidTax)
    }

    /// Formatted YTD taxable income
    var formattedYTDTaxableIncome: String {
        formatCurrency(ytdTaxableIncome, compact: true)
    }

    /// Formatted YTD deductions
    var formattedYTDDeductions: String {
        formatCurrency(ytdDeductions, compact: true)
    }

    /// Payment progress (0.0 to 1.0)
    var paymentProgress: Double {
        guard totalEstimatedTax > 0 else { return 0 }
        return min(1.0, (totalPaidTax as NSDecimalNumber).doubleValue / (totalEstimatedTax as NSDecimalNumber).doubleValue)
    }

    /// Next upcoming quarter
    var nextDueQuarter: QuarterlyTax? {
        quarterlyTaxes.first { !$0.isPaid && $0.dueDate > Date() }
    }

    /// Days until next payment
    var daysUntilNextPayment: Int? {
        guard let next = nextDueQuarter else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: next.dueDate).day
    }

    /// Current quarter name
    var currentQuarterName: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 1...3: return "Q1"
        case 4...6: return "Q2"
        case 7...9: return "Q3"
        default: return "Q4"
        }
    }

    // MARK: - Initialization

    nonisolated init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
    }

    // MARK: - Actions

    /// Load taxes data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        setupAvailableYears()

        do {
            // Load income and deduction data
            try loadIncomeData()

            // Calculate tax estimates
            calculateTaxEstimates()

            // Generate quarterly breakdown
            generateQuarterlyTaxes()

            // Generate tax category breakdown
            generateTaxBreakdown()

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadData()
    }

    /// Select year and reload
    func selectYear(_ year: Int) async {
        selectedYear = year
        await loadData()
    }

    /// Mark quarter as paid
    func markAsPaid(quarter: QuarterlyTax, amount: Decimal) {
        if let index = quarterlyTaxes.firstIndex(where: { $0.id == quarter.id }) {
            quarterlyTaxes[index].paidAmount = amount
            quarterlyTaxes[index].isPaid = true
            quarterlyTaxes[index].paidDate = Date()

            // Recalculate totals
            totalPaidTax = quarterlyTaxes.reduce(Decimal(0)) { $0 + $1.paidAmount }
        }
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func setupAvailableYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        availableYears = Array((currentYear - 2)...currentYear).reversed()
    }

    private func loadIncomeData() throws {
        let assignmentService = try serviceContainer.getAssignmentService()
        let assignments = assignmentService.fetchByYearOrEmpty(selectedYear)

        // Calculate YTD taxable income
        var totalGross: Decimal = 0
        var totalStipends: Decimal = 0

        for assignment in assignments {
            if let pay = assignment.payBreakdown {
                let weeks = Decimal(assignment.durationWeeks)
                totalGross += pay.weeklyGross * weeks
                totalStipends += pay.weeklyStipends * weeks
            }
        }

        // Taxable income is gross minus stipends (simplified)
        let taxableFromAssignments = totalGross - totalStipends

        // Load deductions
        let expenseService = try serviceContainer.getExpenseService()
        let expenses = expenseService.fetchByYearOrEmpty(selectedYear)
        let expenseDeductions = expenses
            .filter { $0.isDeductible }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let mileageService = try serviceContainer.getMileageService()
        let trips = mileageService.fetchByYearOrEmpty(selectedYear)
        let mileageDeductions = trips.reduce(Decimal(0)) { $0 + $1.deductionAmount }

        ytdDeductions = expenseDeductions + mileageDeductions
        ytdTaxableIncome = max(0, taxableFromAssignments - ytdDeductions)
    }

    private func calculateTaxEstimates() {
        // Simplified tax calculation
        // In production, this would use proper tax brackets

        // Federal income tax estimate (using simplified brackets)
        let federalRate: Decimal = 0.22 // 22% bracket for typical travel nurse income
        let federalTax = ytdTaxableIncome * federalRate

        // Self-employment tax (Social Security + Medicare)
        // 15.3% on net self-employment income
        let selfEmploymentRate: Decimal = 0.153
        let selfEmploymentTax = ytdTaxableIncome * selfEmploymentRate

        // Total estimated annual tax
        totalEstimatedTax = federalTax + selfEmploymentTax
    }

    private func generateQuarterlyTaxes() {
        let year = selectedYear
        let quarterlyAmount = totalEstimatedTax / 4

        // Quarterly due dates for estimated taxes
        let dueDates: [(quarter: String, month: Int, day: Int, paymentYear: Int)] = [
            ("Q1", 4, 15, year),      // April 15 for Q1
            ("Q2", 6, 15, year),      // June 15 for Q2
            ("Q3", 9, 15, year),      // September 15 for Q3
            ("Q4", 1, 15, year + 1)   // January 15 next year for Q4
        ]

        quarterlyTaxes = dueDates.map { quarterInfo in
            var components = DateComponents()
            components.year = quarterInfo.paymentYear
            components.month = quarterInfo.month
            components.day = quarterInfo.day
            let dueDate = Calendar.current.date(from: components) ?? Date()

            // Check if this quarter is in the past (simplified paid status)
            let isPast = dueDate < Date()

            return QuarterlyTax(
                quarter: quarterInfo.quarter,
                year: year,
                dueDate: dueDate,
                estimatedAmount: quarterlyAmount,
                paidAmount: isPast ? quarterlyAmount : 0,
                isPaid: isPast,
                paidDate: isPast ? dueDate : nil
            )
        }

        // Recalculate total paid
        totalPaidTax = quarterlyTaxes.reduce(Decimal(0)) { $0 + $1.paidAmount }
    }

    private func generateTaxBreakdown() {
        guard totalEstimatedTax > 0 else {
            taxBreakdown = []
            return
        }

        // Calculate component amounts
        let federalRate: Decimal = 0.22
        let federalTax = ytdTaxableIncome * federalRate

        let socialSecurityRate: Decimal = 0.124
        let socialSecurityTax = ytdTaxableIncome * socialSecurityRate

        let medicareRate: Decimal = 0.029
        let medicareTax = ytdTaxableIncome * medicareRate

        let total = federalTax + socialSecurityTax + medicareTax

        taxBreakdown = [
            TaxBreakdown(
                category: "Federal Income Tax",
                amount: federalTax,
                percentage: total > 0 ? (federalTax as NSDecimalNumber).doubleValue / (total as NSDecimalNumber).doubleValue : 0,
                color: TNColors.primary
            ),
            TaxBreakdown(
                category: "Social Security",
                amount: socialSecurityTax,
                percentage: total > 0 ? (socialSecurityTax as NSDecimalNumber).doubleValue / (total as NSDecimalNumber).doubleValue : 0,
                color: TNColors.accent
            ),
            TaxBreakdown(
                category: "Medicare",
                amount: medicareTax,
                percentage: total > 0 ? (medicareTax as NSDecimalNumber).doubleValue / (total as NSDecimalNumber).doubleValue : 0,
                color: TNColors.secondary
            )
        ]
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Decimal, compact: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"

        if compact && value >= 1000 {
            let thousands = (value as NSDecimalNumber).doubleValue / 1000
            return String(format: "$%.1fK", thousands)
        }

        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }
}

// MARK: - Preview Helper

extension TaxesViewModel {
    static var preview: TaxesViewModel {
        TaxesViewModel()
    }
}
