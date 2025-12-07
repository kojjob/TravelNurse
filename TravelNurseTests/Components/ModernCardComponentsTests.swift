//
//  ModernCardComponentsTests.swift
//  TravelNurseTests
//
//  Tests for modern UI card components matching the design concept
//

import XCTest
import SwiftUI
@testable import TravelNurse

final class ModernCardComponentsTests: XCTestCase {

    // MARK: - StatusBadge Tests

    func testStatusBadge_DueSoon_HasCorrectStyle() {
        let badge = TNStatusBadge(status: .dueSoon, text: "Due Date")
        XCTAssertEqual(badge.status, .dueSoon)
        XCTAssertEqual(badge.text, "Due Date")
    }

    func testStatusBadge_NotPaid_HasCorrectStyle() {
        let badge = TNStatusBadge(status: .unpaid, text: "Not Paid")
        XCTAssertEqual(badge.status, .unpaid)
    }

    func testStatusBadge_Paid_HasCorrectStyle() {
        let badge = TNStatusBadge(status: .paid, text: "Paid")
        XCTAssertEqual(badge.status, .paid)
    }

    func testStatusBadge_Active_HasCorrectStyle() {
        let badge = TNStatusBadge(status: .active, text: "Active")
        XCTAssertEqual(badge.status, .active)
    }

    func testStatusBadge_Disabled_HasCorrectStyle() {
        let badge = TNStatusBadge(status: .disabled, text: "Disabled")
        XCTAssertEqual(badge.status, .disabled)
    }

    // MARK: - QuickMenuItem Tests

    func testQuickMenuItem_HasCorrectProperties() {
        let item = QuickMenuItemData(
            icon: "wifi",
            title: "Internet",
            amount: 64.00,
            frequency: .monthly,
            status: .dueSoon
        )

        XCTAssertEqual(item.icon, "wifi")
        XCTAssertEqual(item.title, "Internet")
        XCTAssertEqual(item.amount, 64.00)
        XCTAssertEqual(item.frequency, .monthly)
        XCTAssertEqual(item.status, .dueSoon)
    }

    func testQuickMenuItem_FormattedAmount() {
        let item = QuickMenuItemData(
            icon: "house",
            title: "Housing",
            amount: 1560.00,
            frequency: .monthly,
            status: .paid
        )

        XCTAssertTrue(item.formattedAmount.contains("1,560"))
    }

    // MARK: - FinanceHealth Tests

    func testFinanceHealthData_ExcellentScore() {
        let health = FinanceHealthData(
            title: "Your Finance is Excellent",
            subtitle: "Have succeeded in reducing outgoing costs.",
            savedAmount: 2050.00,
            progressBars: 8,
            filledBars: 7
        )

        XCTAssertEqual(health.progressBars, 8)
        XCTAssertEqual(health.filledBars, 7)
        XCTAssertTrue(health.progressPercentage > 0.8)
    }

    func testFinanceHealthData_FormattedSavings() {
        let health = FinanceHealthData(
            title: "Test",
            subtitle: "Test",
            savedAmount: 2050.00,
            progressBars: 8,
            filledBars: 7
        )

        XCTAssertTrue(health.formattedSavedAmount.contains("2,050"))
    }

    // MARK: - BalanceCard Tests

    func testBalanceCardData_PositiveChange() {
        let balance = BalanceCardData(
            title: "Your Balance",
            amount: 18560.20,
            changePercentage: 8.0,
            changeAmount: 6282.00,
            isPositive: true
        )

        XCTAssertEqual(balance.amount, 18560.20)
        XCTAssertTrue(balance.isPositive)
        XCTAssertEqual(balance.changePercentage, 8.0)
    }

    func testBalanceCardData_FormattedValues() {
        let balance = BalanceCardData(
            title: "Your Balance",
            amount: 18560.20,
            changePercentage: 8.0,
            changeAmount: 6282.00,
            isPositive: true
        )

        XCTAssertTrue(balance.formattedAmount.contains("18,560"))
        XCTAssertTrue(balance.formattedChange.contains("+8%"))
    }

    // MARK: - DeadlineReminder Tests

    func testDeadlineReminderData_HasCorrectProperties() {
        let reminder = DeadlineReminderData(
            icon: "bolt.fill",
            iconBackgroundColor: .blue,
            amount: 1250.40,
            title: "Electricity Bill Due",
            dueDate: Date(),
            actionTitle: "Pay Now"
        )

        XCTAssertEqual(reminder.title, "Electricity Bill Due")
        XCTAssertEqual(reminder.amount, 1250.40)
        XCTAssertEqual(reminder.actionTitle, "Pay Now")
    }

    func testDeadlineReminderData_FormattedDueDate() {
        let dueDate = Date()
        let reminder = DeadlineReminderData(
            icon: "bolt.fill",
            iconBackgroundColor: .blue,
            amount: 1250.40,
            title: "Electricity Bill Due",
            dueDate: dueDate,
            actionTitle: "Pay Now"
        )

        XCTAssertTrue(reminder.formattedDueDate.contains("Due"))
    }

    // MARK: - Transaction Tests

    func testTransactionData_Income() {
        let transaction = TransactionData(
            icon: "person.fill",
            title: "Vera K.",
            amount: 85.00,
            type: .income,
            status: .moneyIn
        )

        XCTAssertEqual(transaction.type, .income)
        XCTAssertEqual(transaction.status, .moneyIn)
        XCTAssertTrue(transaction.isPositive)
    }

    func testTransactionData_Expense() {
        let transaction = TransactionData(
            icon: "play.rectangle.fill",
            title: "Netflix",
            amount: 57.00,
            type: .expense,
            status: .moneyOut
        )

        XCTAssertEqual(transaction.type, .expense)
        XCTAssertFalse(transaction.isPositive)
    }

    func testTransactionData_Pending() {
        let transaction = TransactionData(
            icon: "lightbulb.fill",
            title: "Light Co.",
            amount: 36.00,
            type: .expense,
            status: .pending
        )

        XCTAssertEqual(transaction.status, .pending)
    }

    // MARK: - AssignmentCard Tests

    func testAssignmentCardData_Active() {
        let card = AssignmentCardData(
            facilityName: "Mayo Clinic",
            location: "Phoenix, AZ",
            amount: 8960.00,
            cardType: "Master Card",
            lastFourDigits: "0234",
            expiryDate: "08/08",
            status: .active,
            cardColor: .red
        )

        XCTAssertEqual(card.status, .active)
        XCTAssertEqual(card.facilityName, "Mayo Clinic")
    }

    func testAssignmentCardData_Disabled() {
        let card = AssignmentCardData(
            facilityName: "Stanford Hospital",
            location: "Palo Alto, CA",
            amount: 2490.00,
            cardType: "Master Card",
            lastFourDigits: "0234",
            expiryDate: "08/08",
            status: .disabled,
            cardColor: .gray
        )

        XCTAssertEqual(card.status, .disabled)
    }

    // MARK: - ExpensesSummary Tests

    func testExpensesSummaryData_WithComparison() {
        let summary = ExpensesSummaryData(
            title: "Your Expenses",
            currentAmount: 4240.60,
            previousAmount: 4070.90,
            comparisonPercentage: -4.0,
            comparisonLabel: "Last month you expenses"
        )

        XCTAssertEqual(summary.currentAmount, 4240.60)
        XCTAssertEqual(summary.comparisonPercentage, -4.0)
        XCTAssertTrue(summary.isDecrease)
    }

    func testExpensesSummaryData_FormattedValues() {
        let summary = ExpensesSummaryData(
            title: "Your Expenses",
            currentAmount: 4240.60,
            previousAmount: 4070.90,
            comparisonPercentage: -4.0,
            comparisonLabel: "Last month you expenses"
        )

        XCTAssertTrue(summary.formattedCurrentAmount.contains("4,240"))
        XCTAssertTrue(summary.formattedPreviousAmount.contains("4,070"))
    }
}
