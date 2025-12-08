//
//  QuarterlyPaymentsViewModel.swift
//  TravelNurse
//
//  ViewModel for managing quarterly estimated tax payments
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel for the QuarterlyPaymentsView
@MainActor
@Observable
final class QuarterlyPaymentsViewModel {

    // MARK: - State

    /// Selected tax year
    var selectedYear: Int = Calendar.current.component(.year, from: Date())

    /// Available years
    private(set) var availableYears: [Int] = []

    /// Quarterly payments for selected year
    private(set) var payments: [QuarterlyPayment] = []

    /// Payment summary
    private(set) var summary: PaymentSummary = PaymentSummary(
        year: Calendar.current.component(.year, from: Date()),
        totalEstimated: 0,
        totalPaid: 0,
        remaining: 0,
        quartersPaid: 0,
        quartersOverdue: 0,
        payments: []
    )

    /// Loading state
    private(set) var isLoading = false

    /// Whether reminders are enabled
    var remindersEnabled = true

    /// Show payment entry sheet
    var showingPaymentSheet = false

    /// Selected payment for editing
    var selectedPayment: QuarterlyPayment?

    /// Show notification permission alert
    var showingNotificationAlert = false

    // MARK: - Computed Properties

    /// Next upcoming payment
    var nextUpcomingPayment: QuarterlyPayment? {
        payments.first { !$0.isPaid && $0.dueDate >= Date() }
    }

    /// Whether there are overdue payments
    var hasOverdue: Bool {
        summary.hasOverdue
    }

    /// Number of overdue payments
    var overdueCount: Int {
        summary.quartersOverdue
    }

    /// Whether there are upcoming payments
    var hasUpcoming: Bool {
        nextUpcomingPayment != nil
    }

    // MARK: - Dependencies

    private let serviceContainer: ServiceContainer
    private var paymentService: QuarterlyPaymentService?
    private var modelContext: ModelContext?

    // MARK: - Initialization

    nonisolated init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
    }

    // MARK: - Actions

    /// Load payment data
    func loadData(modelContext: ModelContext) async {
        self.modelContext = modelContext
        isLoading = true

        setupAvailableYears()
        setupPaymentService()

        await loadPayments()

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadPayments()
    }

    /// Select a different year
    func selectYear(_ year: Int) async {
        selectedYear = year
        await loadPayments()
    }

    /// Show payment sheet for a specific payment
    func showPaymentSheet(for payment: QuarterlyPayment) {
        selectedPayment = payment
        showingPaymentSheet = true
    }

    /// Record a payment
    func recordPayment(amount: Decimal, notes: String?) {
        guard let payment = selectedPayment,
              let service = paymentService else { return }

        service.recordPayment(payment, amount: amount, notes: notes)

        // Refresh data
        Task {
            await loadPayments()
        }

        selectedPayment = nil
    }

    /// Toggle reminders
    func toggleReminders(enabled: Bool) async {
        remindersEnabled = enabled

        guard let service = paymentService else { return }

        if enabled {
            // Check notification permissions
            let notificationService = serviceContainer.notificationService
            let hasPermission = await notificationService?.requestAuthorization() ?? false

            if hasPermission {
                let unpaidPayments = payments.filter { !$0.isPaid }
                service.scheduleReminders(for: unpaidPayments)
            } else {
                remindersEnabled = false
                showingNotificationAlert = true
            }
        } else {
            service.cancelAllReminders()
        }
    }

    /// Open notification settings
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Private Methods

    private func setupAvailableYears() {
        let currentYear = Calendar.current.component(.year, from: Date())
        availableYears = Array((currentYear - 2)...(currentYear + 1)).reversed()
    }

    private func setupPaymentService() {
        guard let modelContext = modelContext else { return }

        let taxService = serviceContainer.taxCalculationService ?? TaxCalculationService()
        let notificationService = serviceContainer.notificationService

        paymentService = QuarterlyPaymentService(
            modelContext: modelContext,
            taxCalculationService: taxService,
            notificationService: notificationService
        )
    }

    private func loadPayments() async {
        guard let service = paymentService else {
            loadFallbackData()
            return
        }

        // Check if we need to generate payments for this year
        var yearPayments = service.fetchPayments(for: selectedYear)

        if yearPayments.isEmpty {
            // Generate payments based on current income
            let incomeData = loadIncomeData()

            yearPayments = service.generatePayments(
                for: selectedYear,
                grossIncome: incomeData.grossIncome,
                deductions: incomeData.deductions,
                state: incomeData.state
            )
        }

        payments = yearPayments.sorted { $0.quarter < $1.quarter }
        summary = service.paymentSummary(for: selectedYear)
    }

    private func loadIncomeData() -> (grossIncome: Decimal, deductions: Decimal, state: USState) {
        // Try to load from assignments and expenses
        var totalGross: Decimal = 0
        var totalDeductions: Decimal = 0
        var taxHomeState: USState = .texas // Default to no-tax state

        do {
            let assignmentService = try serviceContainer.getAssignmentService()
            let assignments = assignmentService.fetchByYearOrEmpty(selectedYear)

            for assignment in assignments {
                if let pay = assignment.payBreakdown {
                    let weeks = Decimal(assignment.durationWeeks)
                    totalGross += pay.weeklyGross * weeks
                }
            }

            let expenseService = try serviceContainer.getExpenseService()
            let expenses = expenseService.fetchByYearOrEmpty(selectedYear)
            totalDeductions = expenses
                .filter { $0.isDeductible }
                .reduce(Decimal(0)) { $0 + $1.amount }

            // Get tax home state
            if let complianceService = serviceContainer.complianceService,
               let taxHome = complianceService.fetchCurrentTaxHome(),
               let state = taxHome.homeAddress?.state {
                taxHomeState = state
            }
        } catch {
            print("Error loading income data: \(error)")
        }

        // Use sample data if no real data
        if totalGross == 0 {
            totalGross = 75000
            totalDeductions = 8000
        }

        return (totalGross, totalDeductions, taxHomeState)
    }

    private func loadFallbackData() {
        // Create sample payments for display
        let currentYear = selectedYear
        let quarterlyAmount: Decimal = 3500

        let dueDates = QuarterlyPayment.standardDueDates(for: currentYear)
        let now = Date()

        payments = dueDates.map { quarterInfo in
            let payment = QuarterlyPayment(
                taxYear: currentYear,
                quarter: quarterInfo.quarter,
                dueDate: quarterInfo.date,
                estimatedAmount: quarterlyAmount,
                federalPayment: quarterlyAmount * Decimal(0.8),
                statePayment: quarterlyAmount * Decimal(0.2)
            )

            // Mark past quarters as paid for demo
            if quarterInfo.date < now {
                payment.recordPayment(amount: quarterlyAmount)
            }

            return payment
        }

        let totalEstimated = quarterlyAmount * 4
        let paidPayments = payments.filter { $0.isPaid }
        let totalPaid = paidPayments.reduce(Decimal(0)) { $0 + $1.paidAmount }

        summary = PaymentSummary(
            year: currentYear,
            totalEstimated: totalEstimated,
            totalPaid: totalPaid,
            remaining: totalEstimated - totalPaid,
            quartersPaid: paidPayments.count,
            quartersOverdue: payments.filter { $0.isOverdue }.count,
            payments: payments
        )
    }
}
