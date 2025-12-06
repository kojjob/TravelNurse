//
//  HomeViewModel.swift
//  TravelNurse
//
//  ViewModel for the redesigned Home screen
//

import Foundation
import SwiftUI
import SwiftData

/// Data structure for state income display
struct StateIncomeData: Identifiable {
    let id = UUID()
    let state: USState
    let income: Decimal

    var formattedIncome: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: income as NSNumber) ?? "$0"
    }
}

/// Data structure for recent activity items
struct RecentActivity: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let iconBackgroundColor: Color
    let amount: Decimal
    let isPositive: Bool
    let badge: String?

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let prefix = isPositive ? "+" : "-"
        return prefix + (formatter.string(from: abs(amount) as NSNumber) ?? "$0.00")
    }

    var amountColor: Color {
        isPositive ? TNColors.success : TNColors.error
    }
}

/// ViewModel managing Home screen state and business logic
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - State

    /// User's display name
    private(set) var userName: String = "Nurse"

    /// Current assignment if any
    private(set) var currentAssignment: Assignment?

    /// Year-to-date gross income
    private(set) var ytdIncome: Decimal = 0

    /// Year-to-date deductions (expenses + mileage)
    private(set) var ytdDeductions: Decimal = 0

    /// Estimated quarterly tax due
    private(set) var estimatedTaxDue: Decimal = 0

    /// States worked with income amounts
    private(set) var statesWorked: [StateIncomeData] = []

    /// Recent activity items
    private(set) var recentActivities: [RecentActivity] = []

    /// Loading state
    private(set) var isLoading = false

    /// Error message if any
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let serviceContainer: ServiceContainer

    // MARK: - Computed Properties

    /// Greeting based on time of day
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    /// Current tax quarter (Q1, Q2, Q3, Q4)
    var currentQuarter: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 1...3:
            return "Q1"
        case 4...6:
            return "Q2"
        case 7...9:
            return "Q3"
        default:
            return "Q4"
        }
    }

    /// Current year
    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// Formatted estimated tax due
    var formattedEstimatedTaxDue: String {
        formatCurrency(estimatedTaxDue)
    }

    /// Next quarterly tax due date
    var formattedTaxDueDate: String {
        let year = currentYear
        let month = Calendar.current.component(.month, from: Date())

        // Quarterly due dates: Apr 15, Jun 15, Sep 15, Jan 15
        let dueDate: Date
        var components = DateComponents()
        components.year = year

        switch month {
        case 1...3:
            components.month = 4
            components.day = 15
        case 4...5:
            components.month = 6
            components.day = 15
        case 6...8:
            components.month = 9
            components.day = 15
        default:
            components.year = year + 1
            components.month = 1
            components.day = 15
        }

        dueDate = Calendar.current.date(from: components) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: dueDate)
    }

    /// Formatted YTD income
    var formattedYTDIncome: String {
        formatCurrency(ytdIncome, compact: true)
    }

    /// Formatted YTD deductions
    var formattedYTDDeductions: String {
        formatCurrency(ytdDeductions, compact: true)
    }

    /// Current week number in assignment
    var currentWeekNumber: Int {
        guard let assignment = currentAssignment else { return 0 }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: assignment.startDate, to: Date()).day ?? 0
        return max(1, (daysSinceStart / 7) + 1)
    }

    /// Total weeks in current assignment
    var totalWeeks: Int {
        currentAssignment?.durationWeeks ?? 0
    }

    /// Weekly rate for current assignment
    var formattedWeeklyRate: String {
        guard let assignment = currentAssignment,
              let pay = assignment.payBreakdown else {
            return "$0/wk"
        }
        return formatCurrency(pay.weeklyGross, compact: true) + "/wk"
    }

    /// Assignment progress (0.0 to 1.0)
    var assignmentProgress: Double {
        currentAssignment?.progressPercentage ?? 0
    }

    // MARK: - New Properties for Modern UI

    /// Whether there's tax due to display
    var hasTaxDue: Bool {
        estimatedTaxDue > 0
    }

    /// YTD income as Decimal value for EarningsCard
    var ytdIncomeValue: Decimal {
        ytdIncome
    }

    /// YTD deductions as Decimal value for EarningsCard
    var ytdDeductionsValue: Decimal {
        ytdDeductions
    }

    /// Income change percentage from last month (placeholder calculation)
    var incomeChangePercent: Double {
        // TODO: Implement actual month-over-month calculation
        // For now, return a positive placeholder
        12.5
    }

    /// Whether the income change is positive
    var isIncomePositive: Bool {
        incomeChangePercent >= 0
    }

    /// Estimated tax due as Decimal value
    var estimatedTaxDueValue: Decimal {
        estimatedTaxDue
    }

    /// Next tax due date as Date object
    var taxDueDate: Date {
        let year = currentYear
        let month = Calendar.current.component(.month, from: Date())

        var components = DateComponents()
        components.year = year

        switch month {
        case 1...3:
            components.month = 4
            components.day = 15
        case 4...5:
            components.month = 6
            components.day = 15
        case 6...8:
            components.month = 9
            components.day = 15
        default:
            components.year = year + 1
            components.month = 1
            components.day = 15
        }

        return Calendar.current.date(from: components) ?? Date()
    }

    /// Compliance badge text for Tax Home quick action
    var complianceBadge: String {
        // TODO: Get actual compliance status from ComplianceService
        "On Track"
    }

    /// Compliance badge color
    var complianceBadgeColor: Color {
        // TODO: Calculate based on actual compliance level
        TNColors.success
    }

    /// Weekly rate as Decimal value for AssignmentProgressCard
    var weeklyRateValue: Decimal {
        currentAssignment?.payBreakdown?.weeklyGross ?? 0
    }

    // MARK: - Dashboard Card Properties

    /// Trend data for income mini chart (last 6 months normalized 0-1)
    var incomeTrendData: [Double] {
        // TODO: Implement actual monthly income trend calculation
        // For now, return sample upward trend data
        [0.3, 0.4, 0.35, 0.5, 0.6, 0.75, 0.85]
    }

    /// Trend data for deductions mini chart (last 6 months normalized 0-1)
    var deductionsTrendData: [Double] {
        // TODO: Implement actual monthly deductions trend calculation
        // For now, return sample trend data
        [0.2, 0.3, 0.25, 0.4, 0.35, 0.5, 0.45]
    }

    /// Percentage of quarterly tax already paid (0.0 to 1.0)
    var taxPaidPercentage: Double {
        // TODO: Implement actual tax payment tracking
        // For now, return placeholder (75% paid as shown in design)
        0.75
    }

    /// Days remaining in current assignment
    var daysRemaining: Int {
        guard let assignment = currentAssignment else { return 0 }
        let endDate = Calendar.current.date(byAdding: .day, value: assignment.durationWeeks * 7, to: assignment.startDate) ?? Date()
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, remaining)
    }

    /// Total days in current assignment
    var totalDays: Int {
        guard let assignment = currentAssignment else { return 0 }
        return assignment.durationWeeks * 7
    }

    /// Assignment location name
    var assignmentLocationName: String {
        currentAssignment?.facilityName ?? "No Current Assignment"
    }

    /// Assignment state abbreviation
    var assignmentState: String {
        currentAssignment?.state?.rawValue ?? ""
    }

    // MARK: - Initialization

    nonisolated init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
    }

    // MARK: - Actions

    /// Load all home screen data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load user profile
            loadUserProfile()

            // Load current assignment
            try loadCurrentAssignment()

            // Load YTD income data
            try loadYTDData()

            // Calculate estimated tax
            calculateEstimatedTax()

            // Load states worked
            try loadStatesWorked()

            // Load recent activity
            try loadRecentActivity()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh all data
    func refresh() async {
        await loadData()
    }

    // MARK: - Private Methods

    private func loadUserProfile() {
        // TODO: Load from UserProfile service when available
        // For now, use default
        userName = "Sarah"
    }

    private func loadCurrentAssignment() throws {
        let service = try serviceContainer.getAssignmentService()
        currentAssignment = service.fetchCurrentAssignment()
    }

    private func loadYTDData() throws {
        let year = currentYear

        // Load assignments for current year
        let assignmentService = try serviceContainer.getAssignmentService()
        let assignments = assignmentService.fetch(byYear: year)

        // Calculate YTD income from assignments
        ytdIncome = assignments.reduce(Decimal(0)) { total, assignment in
            guard let pay = assignment.payBreakdown else { return total }
            let weeks = Decimal(assignment.durationWeeks)
            return total + (pay.weeklyGross * weeks)
        }

        // Load expenses for current year
        let expenseService = try serviceContainer.getExpenseService()
        let expenses = expenseService.fetch(byYear: year)
        let totalExpenses = expenses
            .filter { $0.isDeductible }
            .reduce(Decimal(0)) { $0 + $1.amount }

        // Load mileage for current year
        let mileageService = try serviceContainer.getMileageService()
        let trips = mileageService.fetch(byYear: year)
        let totalMileage = trips.reduce(Decimal(0)) { $0 + $1.deductionAmount }

        ytdDeductions = totalExpenses + totalMileage
    }

    private func calculateEstimatedTax() {
        // Simplified tax estimation
        // In production, this would use proper tax brackets and state-specific calculations
        let taxableIncome = max(0, ytdIncome - ytdDeductions)

        // Rough estimate: 25% effective rate for travel nurses (federal + self-employment)
        let estimatedAnnualTax = taxableIncome * Decimal(0.25)

        // Quarterly payment is 1/4 of annual estimate
        estimatedTaxDue = estimatedAnnualTax / 4
    }

    private func loadStatesWorked() throws {
        let year = currentYear
        let service = try serviceContainer.getAssignmentService()
        let assignments = service.fetch(byYear: year)

        // Group income by state
        var stateIncome: [USState: Decimal] = [:]

        for assignment in assignments {
            guard let state = assignment.state,
                  let pay = assignment.payBreakdown else { continue }

            let income = pay.weeklyGross * Decimal(assignment.durationWeeks)
            stateIncome[state, default: 0] += income
        }

        // Convert to StateIncomeData and sort by income
        statesWorked = stateIncome
            .map { StateIncomeData(state: $0.key, income: $0.value) }
            .sorted { $0.income > $1.income }
    }

    private func loadRecentActivity() throws {
        var activities: [RecentActivity] = []

        // Load recent expenses
        let expenseService = try serviceContainer.getExpenseService()
        let recentExpenses = expenseService.fetchRecent(limit: 3)

        for expense in recentExpenses {
            activities.append(RecentActivity(
                title: expense.category.displayName,
                subtitle: expense.notes ?? expense.category.displayName,
                iconName: expense.category.iconName,
                iconBackgroundColor: expense.category.color,
                amount: expense.amount,
                isPositive: false,
                badge: expense.isDeductible ? "Deductible" : nil
            ))
        }

        // Load recent mileage trips
        let mileageService = try serviceContainer.getMileageService()
        let recentTrips = mileageService.fetchRecent(limit: 2)

        for trip in recentTrips {
            activities.append(RecentActivity(
                title: "Mileage Trip",
                subtitle: "\(String(format: "%.1f", trip.distanceMiles)) miles",
                iconName: "car.fill",
                iconBackgroundColor: TNColors.accent,
                amount: trip.deductionAmount,
                isPositive: false,
                badge: "Deductible"
            ))
        }

        // Sort by most recent and limit to 5
        recentActivities = Array(activities.prefix(5))
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

        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
}

// MARK: - Preview Helper

extension HomeViewModel {
    /// Create a preview instance with mock data
    static var preview: HomeViewModel {
        let viewModel = HomeViewModel()
        // Preview will load data when view appears
        return viewModel
    }
}
