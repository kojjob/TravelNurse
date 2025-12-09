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

    /// Calculated tax components from TaxCalculationService
    private(set) var calculatedFederalTax: Decimal = 0
    private(set) var calculatedStateTax: Decimal = 0
    private(set) var calculatedSelfEmploymentTax: Decimal = 0

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

    /// Convert tax breakdown to chart segments for visualization
    var chartSegments: [ChartSegment] {
        taxBreakdown.map { breakdown in
            ChartSegment(
                label: breakdown.category,
                value: breakdown.amount,
                color: breakdown.color,
                percentage: breakdown.percentage
            )
        }
    }

    /// Effective tax rate as a formatted string
    var formattedEffectiveTaxRate: String {
        guard ytdTaxableIncome > 0 else { return "0%" }
        let rate = (totalEstimatedTax as NSDecimalNumber).doubleValue / (ytdTaxableIncome as NSDecimalNumber).doubleValue * 100
        return String(format: "%.1f%%", rate)
    }

    // MARK: - Initialization

    nonisolated init(serviceContainer: ServiceContainer) {
        self.serviceContainer = serviceContainer
    }

    @MainActor
    convenience init() {
        self.init(serviceContainer: .shared)
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
        // Use TaxCalculationService for accurate progressive bracket calculations
        guard let taxService = serviceContainer.taxCalculationService else {
            // Fallback to simplified calculation if service unavailable
            let federalRate: Decimal = 0.22
            let federalTax = ytdTaxableIncome * federalRate
            let selfEmploymentRate: Decimal = 0.153
            let selfEmploymentTax = ytdTaxableIncome * selfEmploymentRate
            totalEstimatedTax = federalTax + selfEmploymentTax
            return
        }

        // Get user's tax home state for state tax calculation
        let taxHomeState = getUserTaxHomeState()

        // Calculate comprehensive tax using real progressive brackets
        let taxResult = taxService.calculateTotalTax(
            grossIncome: ytdTaxableIncome + ytdDeductions, // Pre-deduction income
            deductions: ytdDeductions,
            state: taxHomeState,
            isSelfEmployed: true // Travel nurses typically file as self-employed for stipends
        )

        // Store component values for breakdown
        calculatedFederalTax = taxResult.federalTax
        calculatedStateTax = taxResult.stateTax
        calculatedSelfEmploymentTax = taxResult.selfEmploymentTax

        // Total estimated annual tax
        totalEstimatedTax = taxResult.totalTax
    }

    /// Get user's tax home state, defaulting to Texas (no state tax) if not set
    private func getUserTaxHomeState() -> USState {
        // TODO: In future, get from UserProfile.taxHomeState via userService
        // For now, default to Texas (no state income tax)
        // This is a safe default as Texas has no state income tax
        return .texas
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

        // Use calculated values from TaxCalculationService
        let federalTax = calculatedFederalTax
        let stateTax = calculatedStateTax
        let selfEmploymentTax = calculatedSelfEmploymentTax

        // Break down self-employment tax into Social Security (12.4%) and Medicare (2.9%)
        // Self-employment tax is 15.3% total = 12.4% SS + 2.9% Medicare
        let ssToPortion: Decimal = 0.124 / 0.153
        let medicarePortion: Decimal = 0.029 / 0.153
        let socialSecurityTax = selfEmploymentTax * ssToPortion
        let medicareTax = selfEmploymentTax * medicarePortion

        let total = federalTax + stateTax + selfEmploymentTax

        var breakdown: [TaxBreakdown] = [
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

        // Add state tax if applicable (non-zero)
        if stateTax > 0 {
            breakdown.append(TaxBreakdown(
                category: "State Income Tax",
                amount: stateTax,
                percentage: total > 0 ? (stateTax as NSDecimalNumber).doubleValue / (total as NSDecimalNumber).doubleValue : 0,
                color: TNColors.warning
            ))
        }

        taxBreakdown = breakdown
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

