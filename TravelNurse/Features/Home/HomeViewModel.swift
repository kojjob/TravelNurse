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

    /// Total miles tracked this year
    private(set) var totalMiles: Double = 0

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
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<21:
            return "Good evening,"
        default:
            return "Good night,"
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

    /// Income change percentage from last month
    var incomeChangePercent: Double {
        calculateMonthOverMonthChange()
    }

    /// Calculate actual month-over-month income change
    private func calculateMonthOverMonthChange() -> Double {
        guard let assignmentService = serviceContainer.assignmentService else { return 0 }

        let calendar = Calendar.current
        let now = Date()

        // Get current month range
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let currentMonthEnd = calendar.date(byAdding: .month, value: 1, to: currentMonthStart),
              let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return 0
        }

        let assignments = assignmentService.fetchAllOrEmpty()

        // Calculate income for current month (pro-rated)
        let currentMonthIncome = calculateIncomeForPeriod(
            assignments: assignments,
            startDate: currentMonthStart,
            endDate: min(currentMonthEnd, now)
        )

        // Calculate income for previous month
        let previousMonthIncome = calculateIncomeForPeriod(
            assignments: assignments,
            startDate: previousMonthStart,
            endDate: currentMonthStart
        )

        // Calculate percentage change
        guard previousMonthIncome > 0 else {
            return currentMonthIncome > 0 ? 100 : 0
        }

        let change = ((currentMonthIncome - previousMonthIncome) / previousMonthIncome) * 100
        return Double(truncating: change as NSNumber)
    }

    /// Calculate income for a specific date range from assignments
    private func calculateIncomeForPeriod(assignments: [Assignment], startDate: Date, endDate: Date) -> Decimal {
        let calendar = Calendar.current

        return assignments.reduce(Decimal.zero) { total, assignment in
            guard let pay = assignment.payBreakdown else { return total }

            // Check if assignment overlaps with the period
            let assignmentEnd = assignment.endDate
            guard assignment.startDate < endDate && assignmentEnd > startDate else { return total }

            // Calculate overlap
            let overlapStart = max(assignment.startDate, startDate)
            let overlapEnd = min(assignmentEnd, endDate)

            let days = calendar.dateComponents([.day], from: overlapStart, to: overlapEnd).day ?? 0
            guard days > 0 else { return total }

            // Calculate daily rate and pro-rate
            let dailyRate = pay.weeklyGross / 7
            return total + (dailyRate * Decimal(days))
        }
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
        guard let complianceService = serviceContainer.complianceService else {
            return "Unknown"
        }

        let level = complianceService.currentComplianceLevel()
        switch level {
        case .excellent:
            return "Excellent"
        case .good:
            return "On Track"
        case .atRisk, .nonCompliant:
            return "At Risk"
        case .unknown:
            return "Setup Needed"
        }
    }

    /// Compliance badge color
    var complianceBadgeColor: Color {
        guard let complianceService = serviceContainer.complianceService else {
            return TNColors.textSecondary
        }

        let level = complianceService.currentComplianceLevel()
        switch level {
        case .excellent:
            return TNColors.success
        case .good:
            return TNColors.primary
        case .atRisk, .nonCompliant:
            return TNColors.error
        case .unknown:
            return TNColors.warning
        }
    }

    /// Weekly rate as Decimal value for AssignmentProgressCard
    var weeklyRateValue: Decimal {
        currentAssignment?.payBreakdown?.weeklyGross ?? 0
    }

    // MARK: - Dashboard Card Properties

    /// Trend data for income mini chart (last 6 months normalized 0-1)
    var incomeTrendData: [Double] {
        calculateMonthlyTrendData(type: .income)
    }

    /// Trend data for deductions mini chart (last 6 months normalized 0-1)
    var deductionsTrendData: [Double] {
        calculateMonthlyTrendData(type: .deductions)
    }

    /// Percentage of quarterly tax already paid (0.0 to 1.0)
    /// Note: This calculates based on time elapsed in the quarter as a proxy
    /// until actual payment tracking is implemented
    var taxPaidPercentage: Double {
        calculateQuarterProgress()
    }

    /// Type of trend data to calculate
    private enum TrendType {
        case income
        case deductions
    }

    /// Calculate monthly trend data for the last 6 months
    private func calculateMonthlyTrendData(type: TrendType) -> [Double] {
        let calendar = Calendar.current
        let now = Date()

        // Get the start of the current month and go back 6 months
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return Array(repeating: 0.5, count: 6)
        }

        var monthlyValues: [Decimal] = []

        // Calculate values for each of the last 6 months
        for monthOffset in (0..<6).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: currentMonthStart),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                monthlyValues.append(0)
                continue
            }

            let value: Decimal
            switch type {
            case .income:
                value = calculateIncomeForMonth(startDate: monthStart, endDate: monthEnd)
            case .deductions:
                value = calculateDeductionsForMonth(startDate: monthStart, endDate: monthEnd)
            }
            monthlyValues.append(value)
        }

        // Normalize to 0-1 range
        let maxValue = monthlyValues.max() ?? 1
        guard maxValue > 0 else {
            return Array(repeating: 0.1, count: 6)
        }

        return monthlyValues.map { value in
            let normalized = Double(truncating: (value / maxValue) as NSNumber)
            return max(0.1, min(1.0, normalized)) // Ensure minimum visibility
        }
    }

    /// Calculate income for a specific month
    private func calculateIncomeForMonth(startDate: Date, endDate: Date) -> Decimal {
        guard let assignmentService = serviceContainer.assignmentService else { return 0 }
        let assignments = assignmentService.fetchAllOrEmpty()
        return calculateIncomeForPeriod(assignments: assignments, startDate: startDate, endDate: endDate)
    }

    /// Calculate deductions for a specific month
    private func calculateDeductionsForMonth(startDate: Date, endDate: Date) -> Decimal {
        var total: Decimal = 0

        // Get expenses
        if let expenseService = serviceContainer.expenseService {
            let expenses = expenseService.fetchAllOrEmpty()
            let monthExpenses = expenses.filter {
                $0.date >= startDate && $0.date < endDate && $0.isDeductible
            }
            total += monthExpenses.reduce(Decimal.zero) { $0 + $1.amount }
        }

        // Get mileage deductions
        if let mileageService = serviceContainer.mileageService {
            let trips = mileageService.fetchAllOrEmpty()
            let monthTrips = trips.filter {
                $0.startTime >= startDate && $0.startTime < endDate
            }
            total += monthTrips.reduce(Decimal.zero) { $0 + $1.deductionAmount }
        }

        return total
    }

    /// Calculate progress through the current quarter (as a proxy for tax paid)
    private func calculateQuarterProgress() -> Double {
        let calendar = Calendar.current
        let now = Date()

        let month = calendar.component(.month, from: now)

        // Determine which quarter we're in and the quarter boundaries
        let quarterStartMonth: Int
        let quarterEndMonth: Int

        switch month {
        case 1...3:
            quarterStartMonth = 1
            quarterEndMonth = 4
        case 4...6:
            quarterStartMonth = 4
            quarterEndMonth = 7
        case 7...9:
            quarterStartMonth = 7
            quarterEndMonth = 10
        default:
            quarterStartMonth = 10
            quarterEndMonth = 1 // Next year
        }

        // Calculate days elapsed in quarter
        guard let quarterStart = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: now),
            month: quarterStartMonth,
            day: 1
        )) else {
            return 0.5
        }

        let nextYear = quarterEndMonth == 1 ? calendar.component(.year, from: now) + 1 : calendar.component(.year, from: now)
        guard let quarterEnd = calendar.date(from: DateComponents(
            year: nextYear,
            month: quarterEndMonth,
            day: 1
        )) else {
            return 0.5
        }

        let totalDays = calendar.dateComponents([.day], from: quarterStart, to: quarterEnd).day ?? 90
        let elapsedDays = calendar.dateComponents([.day], from: quarterStart, to: now).day ?? 0

        return min(1.0, max(0.0, Double(elapsedDays) / Double(totalDays)))
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

    init(serviceContainer: ServiceContainer = .shared) {
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
        // Try to load from UserDefaults where settings are stored
        let defaults = UserDefaults.standard

        // Check for stored profile data from SettingsViewModel
        if let data = defaults.data(forKey: "settings.profile"),
           let profile = try? JSONDecoder().decode(StoredProfile.self, from: data) {
            userName = profile.firstName.isEmpty ? "Nurse" : profile.firstName
        } else {
            // Fallback to default
            userName = "Nurse"
        }
    }

    /// Minimal profile struct for decoding stored settings
    private struct StoredProfile: Codable {
        let firstName: String
        let lastName: String
    }

    private func loadCurrentAssignment() throws {
        let service = try serviceContainer.getAssignmentService()
        currentAssignment = service.fetchCurrentAssignmentOrNil()
    }

    private func loadYTDData() throws {
        let year = currentYear

        // Load assignments for current year
        let assignmentService = try serviceContainer.getAssignmentService()
        let assignments = assignmentService.fetchByYearOrEmpty(year)

        // Calculate YTD income from assignments
        ytdIncome = assignments.reduce(Decimal(0)) { total, assignment in
            guard let pay = assignment.payBreakdown else { return total }
            let weeks = Decimal(assignment.durationWeeks)
            return total + (pay.weeklyGross * weeks)
        }

        // Load expenses for current year
        let expenseService = try serviceContainer.getExpenseService()
        let expenses = expenseService.fetchByYearOrEmpty(year)
        let totalExpenses = expenses
            .filter { $0.isDeductible }
            .reduce(Decimal(0)) { $0 + $1.amount }

        // Load mileage for current year
        let mileageService = try serviceContainer.getMileageService()
        let trips = mileageService.fetchByYearOrEmpty(year)
        let totalMileage = trips.reduce(Decimal(0)) { $0 + $1.deductionAmount }

        // Calculate total miles
        totalMiles = trips.reduce(0.0) { $0 + $1.distanceMiles }

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
        let assignments = service.fetchByYearOrEmpty(year)

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
        let recentExpenses = expenseService.fetchRecentOrEmpty(limit: 3)

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
        let recentTrips = mileageService.fetchRecentOrEmpty(limit: 2)

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

