//
//  QuarterlyPaymentServiceTests.swift
//  TravelNurseTests
//
//  Tests for QuarterlyPaymentService and QuarterlyPayment model
//

import XCTest
import SwiftData
@testable import TravelNurse

// MARK: - QuarterlyPayment Model Tests

final class QuarterlyPaymentTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_setsCorrectValues() {
        let year = 2025
        let quarter = 2
        let dueDate = makeDate(year: 2025, month: 6, day: 15)
        let estimatedAmount: Decimal = 3500

        let payment = QuarterlyPayment(
            taxYear: year,
            quarter: quarter,
            dueDate: dueDate,
            estimatedAmount: estimatedAmount
        )

        XCTAssertEqual(payment.taxYear, year)
        XCTAssertEqual(payment.quarter, quarter)
        XCTAssertEqual(payment.dueDate, dueDate)
        XCTAssertEqual(payment.estimatedAmount, estimatedAmount)
        XCTAssertEqual(payment.paidAmount, 0)
        XCTAssertFalse(payment.isPaid)
        XCTAssertNil(payment.paidDate)
    }

    func test_quarterName_returnsCorrectFormat() {
        let payment = makePayment(quarter: 3)

        XCTAssertEqual(payment.quarterName, "Q3")
    }

    func test_fullName_includesYearAndQuarter() {
        let payment = makePayment(quarter: 2, year: 2025)

        XCTAssertEqual(payment.fullName, "Q2 2025")
    }

    // MARK: - Remaining Amount Tests

    func test_remainingAmount_whenUnpaid_returnsFullAmount() {
        let payment = makePayment(estimatedAmount: 3500)

        XCTAssertEqual(payment.remainingAmount, 3500)
    }

    func test_remainingAmount_whenPartiallyPaid_returnsCorrectAmount() {
        let payment = makePayment(estimatedAmount: 3500)
        payment.paidAmount = 1000

        XCTAssertEqual(payment.remainingAmount, 2500)
    }

    func test_remainingAmount_whenFullyPaid_returnsZero() {
        let payment = makePayment(estimatedAmount: 3500)
        payment.paidAmount = 3500

        XCTAssertEqual(payment.remainingAmount, 0)
    }

    func test_remainingAmount_whenOverpaid_returnsZero() {
        let payment = makePayment(estimatedAmount: 3500)
        payment.paidAmount = 4000

        XCTAssertEqual(payment.remainingAmount, 0)
    }

    // MARK: - Payment Status Tests

    func test_status_whenPaid_returnsPaid() {
        let payment = makePayment()
        payment.isPaid = true

        XCTAssertEqual(payment.status, .paid)
    }

    func test_status_whenOverdue_returnsOverdue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let payment = makePayment(dueDate: pastDate)
        payment.isPaid = false

        XCTAssertEqual(payment.status, .overdue)
    }

    func test_status_whenDueSoon_returnsDueSoon() {
        let soonDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let payment = makePayment(dueDate: soonDate)
        payment.isPaid = false

        XCTAssertEqual(payment.status, .dueSoon)
    }

    func test_status_whenUpcoming_returnsUpcoming() {
        let upcomingDate = Calendar.current.date(byAdding: .day, value: 20, to: Date())!
        let payment = makePayment(dueDate: upcomingDate)
        payment.isPaid = false

        XCTAssertEqual(payment.status, .upcoming)
    }

    func test_status_whenScheduled_returnsScheduled() {
        let farDate = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let payment = makePayment(dueDate: farDate)
        payment.isPaid = false

        XCTAssertEqual(payment.status, .scheduled)
    }

    // MARK: - Record Payment Tests

    func test_recordPayment_setsAmountAndDate() {
        let payment = makePayment(estimatedAmount: 3500)

        payment.recordPayment(amount: 3500, notes: "Check #123")

        XCTAssertEqual(payment.paidAmount, 3500)
        XCTAssertTrue(payment.isPaid)
        XCTAssertNotNil(payment.paidDate)
        XCTAssertEqual(payment.paymentNotes, "Check #123")
    }

    func test_recordPayment_partialAmount_notMarkedAsPaid() {
        let payment = makePayment(estimatedAmount: 3500)

        payment.recordPayment(amount: 2000)

        XCTAssertEqual(payment.paidAmount, 2000)
        XCTAssertFalse(payment.isPaid)
    }

    // MARK: - Static Helper Tests

    func test_standardDueDates_returnsCorrectDates() {
        let dueDates = QuarterlyPayment.standardDueDates(for: 2025)

        XCTAssertEqual(dueDates.count, 4)

        // Q1 - April 15
        XCTAssertEqual(dueDates[0].quarter, 1)
        XCTAssertEqual(Calendar.current.component(.month, from: dueDates[0].date), 4)
        XCTAssertEqual(Calendar.current.component(.day, from: dueDates[0].date), 15)

        // Q2 - June 15
        XCTAssertEqual(dueDates[1].quarter, 2)
        XCTAssertEqual(Calendar.current.component(.month, from: dueDates[1].date), 6)

        // Q3 - September 15
        XCTAssertEqual(dueDates[2].quarter, 3)
        XCTAssertEqual(Calendar.current.component(.month, from: dueDates[2].date), 9)

        // Q4 - January 15 of next year
        XCTAssertEqual(dueDates[3].quarter, 4)
        XCTAssertEqual(Calendar.current.component(.month, from: dueDates[3].date), 1)
        XCTAssertEqual(Calendar.current.component(.year, from: dueDates[3].date), 2026)
    }

    func test_createForYear_createsAllQuarters() {
        let payments = QuarterlyPayment.createForYear(
            2025,
            totalEstimatedTax: 14000,
            federalTax: 11200,
            stateTax: 2800,
            state: .california
        )

        XCTAssertEqual(payments.count, 4)

        for (index, payment) in payments.enumerated() {
            XCTAssertEqual(payment.quarter, index + 1)
            XCTAssertEqual(payment.taxYear, 2025)
            XCTAssertEqual(payment.estimatedAmount, 3500)
            XCTAssertEqual(payment.federalPayment, 2800)
            XCTAssertEqual(payment.statePayment, 700)
        }
    }

    // MARK: - Helpers

    private func makePayment(
        quarter: Int = 1,
        year: Int = 2025,
        dueDate: Date? = nil,
        estimatedAmount: Decimal = 3500
    ) -> QuarterlyPayment {
        let date = dueDate ?? makeDate(year: year, month: 4, day: 15)
        return QuarterlyPayment(
            taxYear: year,
            quarter: quarter,
            dueDate: date,
            estimatedAmount: estimatedAmount
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}

// MARK: - PaymentStatus Tests

final class PaymentStatusTests: XCTestCase {

    func test_displayName_returnsCorrectStrings() {
        XCTAssertEqual(PaymentStatus.paid.displayName, "Paid")
        XCTAssertEqual(PaymentStatus.overdue.displayName, "Overdue")
        XCTAssertEqual(PaymentStatus.dueSoon.displayName, "Due Soon")
        XCTAssertEqual(PaymentStatus.upcoming.displayName, "Upcoming")
        XCTAssertEqual(PaymentStatus.scheduled.displayName, "Scheduled")
    }

    func test_iconName_returnsValidSFSymbols() {
        // All status icon names should be valid SF Symbols
        let validIcons = [
            "checkmark.circle.fill",
            "exclamationmark.circle.fill",
            "clock.fill",
            "calendar.badge.clock",
            "calendar"
        ]

        XCTAssertTrue(validIcons.contains(PaymentStatus.paid.iconName))
        XCTAssertTrue(validIcons.contains(PaymentStatus.overdue.iconName))
        XCTAssertTrue(validIcons.contains(PaymentStatus.dueSoon.iconName))
        XCTAssertTrue(validIcons.contains(PaymentStatus.upcoming.iconName))
        XCTAssertTrue(validIcons.contains(PaymentStatus.scheduled.iconName))
    }
}

// MARK: - PaymentSummary Tests

final class PaymentSummaryTests: XCTestCase {

    func test_progress_calculatesCorrectly() {
        let summary = PaymentSummary(
            year: 2025,
            totalEstimated: 14000,
            totalPaid: 7000,
            remaining: 7000,
            quartersPaid: 2,
            quartersOverdue: 0,
            payments: []
        )

        XCTAssertEqual(summary.progress, 0.5, accuracy: 0.01)
    }

    func test_progress_whenZeroEstimated_returnsZero() {
        let summary = PaymentSummary(
            year: 2025,
            totalEstimated: 0,
            totalPaid: 0,
            remaining: 0,
            quartersPaid: 0,
            quartersOverdue: 0,
            payments: []
        )

        XCTAssertEqual(summary.progress, 0)
    }

    func test_isFullyPaid_whenAllQuartersPaid() {
        let summary = PaymentSummary(
            year: 2025,
            totalEstimated: 14000,
            totalPaid: 14000,
            remaining: 0,
            quartersPaid: 4,
            quartersOverdue: 0,
            payments: []
        )

        XCTAssertTrue(summary.isFullyPaid)
    }

    func test_isFullyPaid_whenNotAllPaid() {
        let summary = PaymentSummary(
            year: 2025,
            totalEstimated: 14000,
            totalPaid: 10500,
            remaining: 3500,
            quartersPaid: 3,
            quartersOverdue: 0,
            payments: []
        )

        XCTAssertFalse(summary.isFullyPaid)
    }

    func test_hasOverdue_whenOverdueExists() {
        let summary = PaymentSummary(
            year: 2025,
            totalEstimated: 14000,
            totalPaid: 3500,
            remaining: 10500,
            quartersPaid: 1,
            quartersOverdue: 1,
            payments: []
        )

        XCTAssertTrue(summary.hasOverdue)
    }

    func test_formattedAmounts_includeDollarSign() {
        let summary = PaymentSummary(
            year: 2025,
            totalEstimated: 14000,
            totalPaid: 7000,
            remaining: 7000,
            quartersPaid: 2,
            quartersOverdue: 0,
            payments: []
        )

        XCTAssertTrue(summary.formattedTotalEstimated.contains("$"))
        XCTAssertTrue(summary.formattedTotalPaid.contains("$"))
        XCTAssertTrue(summary.formattedRemaining.contains("$"))
    }
}

// MARK: - QuarterlyPaymentService Tests

@MainActor
final class QuarterlyPaymentServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var taxCalculationService: TaxCalculationService!
    var sut: QuarterlyPaymentService!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            QuarterlyPayment.self,
            UserProfile.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer.mainContext
            taxCalculationService = TaxCalculationService()
            sut = QuarterlyPaymentService(
                modelContext: modelContext,
                taxCalculationService: taxCalculationService
            )
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() async throws {
        sut = nil
        taxCalculationService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Generate Payments Tests

    func test_generatePayments_createsAllQuarters() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        XCTAssertEqual(payments.count, 4)
        XCTAssertEqual(payments[0].quarter, 1)
        XCTAssertEqual(payments[1].quarter, 2)
        XCTAssertEqual(payments[2].quarter, 3)
        XCTAssertEqual(payments[3].quarter, 4)
    }

    func test_generatePayments_calculatesCorrectAmounts() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 80000,
            deductions: 10000,
            state: .texas
        )

        // All quarters should have the same amount
        let firstAmount = payments[0].estimatedAmount
        for payment in payments {
            XCTAssertEqual(payment.estimatedAmount, firstAmount)
        }

        // Total should be calculated by TaxCalculationService
        let totalEstimated = payments.reduce(Decimal(0)) { $0 + $1.estimatedAmount }
        XCTAssertGreaterThan(totalEstimated, 0)
    }

    func test_generatePayments_existingPayments_updatesUnpaid() {
        // First generation
        let initialPayments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        // Mark first quarter as paid
        initialPayments[0].recordPayment(amount: initialPayments[0].estimatedAmount)

        // Second generation with higher income
        let updatedPayments = sut.generatePayments(
            for: 2025,
            grossIncome: 100000,
            deductions: 8000,
            state: .texas
        )

        // First quarter should still be paid (not updated)
        XCTAssertTrue(updatedPayments[0].isPaid)

        // Other quarters should be updated with new amount
        XCTAssertFalse(updatedPayments[1].isPaid)
    }

    // MARK: - Fetch Methods Tests

    func test_fetchPayments_returnsForCorrectYear() {
        _ = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        let payments2025 = sut.fetchPayments(for: 2025)
        let payments2024 = sut.fetchPayments(for: 2024)

        XCTAssertEqual(payments2025.count, 4)
        XCTAssertEqual(payments2024.count, 0)
    }

    func test_fetchUnpaidPayments_returnsOnlyUnpaid() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        // Mark first two as paid
        payments[0].recordPayment(amount: payments[0].estimatedAmount)
        payments[1].recordPayment(amount: payments[1].estimatedAmount)

        let unpaid = sut.fetchUnpaidPayments()

        XCTAssertEqual(unpaid.count, 2)
        XCTAssertTrue(unpaid.allSatisfy { !$0.isPaid })
    }

    func test_nextUpcomingPayment_returnsCorrectPayment() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        // Mark first quarter as paid
        payments[0].recordPayment(amount: payments[0].estimatedAmount)

        let next = sut.nextUpcomingPayment()

        // Should skip paid Q1 and return Q2 (if in future) or first unpaid future quarter
        XCTAssertNotNil(next)
        XCTAssertFalse(next?.isPaid ?? true)
    }

    // MARK: - Record Payment Tests

    func test_recordPayment_updatesPayment() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        let payment = payments[0]

        sut.recordPayment(payment, amount: 3500, notes: "Paid via IRS Direct Pay")

        XCTAssertEqual(payment.paidAmount, 3500)
        XCTAssertTrue(payment.isPaid)
        XCTAssertEqual(payment.paymentNotes, "Paid via IRS Direct Pay")
    }

    // MARK: - Payment Summary Tests

    func test_paymentSummary_calculatesCorrectly() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        // Mark first two quarters as paid
        sut.recordPayment(payments[0], amount: payments[0].estimatedAmount)
        sut.recordPayment(payments[1], amount: payments[1].estimatedAmount)

        let summary = sut.paymentSummary(for: 2025)

        XCTAssertEqual(summary.year, 2025)
        XCTAssertEqual(summary.quartersPaid, 2)
        XCTAssertEqual(summary.progress, 0.5, accuracy: 0.01)
    }

    // MARK: - Delete Payment Tests

    func test_deletePayment_removesFromContext() {
        let payments = sut.generatePayments(
            for: 2025,
            grossIncome: 75000,
            deductions: 8000,
            state: .texas
        )

        let paymentToDelete = payments[0]
        sut.deletePayment(paymentToDelete)

        let remainingPayments = sut.fetchPayments(for: 2025)
        XCTAssertEqual(remainingPayments.count, 3)
    }
}
