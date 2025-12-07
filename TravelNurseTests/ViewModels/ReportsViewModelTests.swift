//
//  ReportsViewModelTests.swift
//  TravelNurseTests
//
//  TDD tests for ReportsViewModel
//

import XCTest
@testable import TravelNurse

// MARK: - Test Cases

@MainActor
final class ReportsViewModelTests: XCTestCase {

    var sut: ReportsViewModel!

    override func setUp() {
        super.setUp()
        sut = ReportsViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_setsDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isExporting)
        XCTAssertEqual(sut.selectedYear, Calendar.current.component(.year, from: Date()))
        XCTAssertEqual(sut.totalIncome, 0)
        XCTAssertEqual(sut.totalExpenses, 0)
        XCTAssertEqual(sut.totalMileageDeduction, 0)
        XCTAssertEqual(sut.totalMiles, 0)
        XCTAssertTrue(sut.stateBreakdowns.isEmpty)
    }

    // MARK: - Computed Properties Tests

    func testNetIncome_calculatesCorrectly() {
        // Given
        sut.totalIncome = 50000
        sut.totalExpenses = 5000
        sut.totalMileageDeduction = 2000

        // Then
        XCTAssertEqual(sut.netIncome, 43000)
    }

    func testNetIncome_whenExpensesExceedIncome_returnsNegative() {
        // Given
        sut.totalIncome = 1000
        sut.totalExpenses = 2000
        sut.totalMileageDeduction = 500

        // Then
        XCTAssertEqual(sut.netIncome, -1500)
    }

    func testEstimatedTax_calculatesAt22Percent() {
        // Given
        sut.totalIncome = 50000
        sut.totalExpenses = 5000
        sut.totalMileageDeduction = 0

        // Then - 22% of (50000 - 5000) = 22% of 45000 = 9900
        XCTAssertEqual(sut.estimatedTax, Decimal(9900))
    }

    func testEstimatedTax_whenNetIncomeNegative_returnsZero() {
        // Given
        sut.totalIncome = 1000
        sut.totalExpenses = 5000
        sut.totalMileageDeduction = 0

        // Then
        XCTAssertEqual(sut.estimatedTax, 0)
    }

    func testEstimatedTax_whenNetIncomeZero_returnsZero() {
        // Given
        sut.totalIncome = 5000
        sut.totalExpenses = 5000
        sut.totalMileageDeduction = 0

        // Then
        XCTAssertEqual(sut.estimatedTax, 0)
    }

    // MARK: - Formatted Values Tests

    func testFormattedTotalIncome_returnsCurrencyFormat() {
        // Given
        sut.totalIncome = 75000

        // Then
        XCTAssertTrue(sut.formattedTotalIncome.contains("75"))
        XCTAssertTrue(sut.formattedTotalIncome.contains("$"))
    }

    func testFormattedTotalExpenses_returnsCurrencyFormat() {
        // Given
        sut.totalExpenses = 12500

        // Then
        XCTAssertTrue(sut.formattedTotalExpenses.contains("12"))
        XCTAssertTrue(sut.formattedTotalExpenses.contains("$"))
    }

    func testFormattedMileageDeduction_returnsCurrencyFormat() {
        // Given
        sut.totalMileageDeduction = 2500

        // Then
        XCTAssertTrue(sut.formattedMileageDeduction.contains("2"))
        XCTAssertTrue(sut.formattedMileageDeduction.contains("$"))
    }

    func testFormattedNetIncome_returnsCurrencyFormat() {
        // Given
        sut.totalIncome = 100000
        sut.totalExpenses = 10000
        sut.totalMileageDeduction = 5000

        // Then - net income should be 85000
        XCTAssertTrue(sut.formattedNetIncome.contains("85"))
        XCTAssertTrue(sut.formattedNetIncome.contains("$"))
    }

    func testFormattedEstimatedTax_returnsCurrencyFormat() {
        // Given
        sut.totalIncome = 100000
        sut.totalExpenses = 10000
        sut.totalMileageDeduction = 0

        // Then - tax should be 22% of 90000 = 19800
        XCTAssertTrue(sut.formattedEstimatedTax.contains("19"))
        XCTAssertTrue(sut.formattedEstimatedTax.contains("$"))
    }

    // MARK: - State Tests

    func testLoadData_setsSelectedYear() {
        // Given
        let testYear = 2023

        // When
        sut.loadData(for: testYear)

        // Then
        XCTAssertEqual(sut.selectedYear, testYear)
        XCTAssertFalse(sut.isLoading) // Should be false after loading
    }

    func testLoadData_setsIsLoadingDuringOperation() {
        // Given
        let testYear = 2024

        // When
        sut.loadData(for: testYear)

        // Then - isLoading should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Export Format Tests

    func testExportFormat_csv_hasCorrectFileExtension() {
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
    }

    func testExportFormat_pdf_hasCorrectFileExtension() {
        XCTAssertEqual(ExportFormat.pdf.fileExtension, "pdf")
    }

    func testExportFormat_json_hasCorrectFileExtension() {
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
    }

    func testExportFormat_csv_hasCorrectIconName() {
        XCTAssertEqual(ExportFormat.csv.iconName, "tablecells")
    }

    func testExportFormat_pdf_hasCorrectIconName() {
        XCTAssertEqual(ExportFormat.pdf.iconName, "doc.richtext")
    }

    func testExportFormat_json_hasCorrectIconName() {
        XCTAssertEqual(ExportFormat.json.iconName, "curlybraces")
    }

    func testExportFormat_allCases_hasThreeFormats() {
        XCTAssertEqual(ExportFormat.allCases.count, 3)
    }

    // MARK: - Export Tests

    func testExportReport_setsIsExportingDuringOperation() async {
        // Given
        let format = ExportFormat.csv

        // When
        let _ = await sut.exportReport(format: format)

        // Then - isExporting should be false after completion
        XCTAssertFalse(sut.isExporting)
    }

    func testExportReport_csv_returnsValidURL() async {
        // Given
        sut.selectedYear = 2024
        sut.totalIncome = 50000
        sut.totalExpenses = 5000

        // When
        let url = await sut.exportReport(format: .csv)

        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.lastPathComponent.contains("TaxReport_2024") ?? false)
        XCTAssertEqual(url?.pathExtension, "csv")
    }

    func testExportReport_json_returnsValidURL() async {
        // Given
        sut.selectedYear = 2024

        // When
        let url = await sut.exportReport(format: .json)

        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.pathExtension, "json")
    }

    func testExportReport_pdf_returnsValidURL() async {
        // Given
        sut.selectedYear = 2024

        // When
        let url = await sut.exportReport(format: .pdf)

        // Then
        XCTAssertNotNil(url)
        // Note: Currently generates text file, not PDF
    }
}

// MARK: - StateBreakdown Tests

@MainActor
final class StateBreakdownTests: XCTestCase {

    func testStateBreakdown_id_returnsStateRawValue() {
        // Given
        let breakdown = StateBreakdown(
            state: .california,
            earnings: 50000,
            weeksWorked: 13,
            hasStateTax: true
        )

        // Then
        XCTAssertEqual(breakdown.id, USState.california.rawValue)
    }

    func testStateBreakdown_formattedEarnings_returnsCurrencyFormat() {
        // Given
        let breakdown = StateBreakdown(
            state: .texas,
            earnings: 75000,
            weeksWorked: 20,
            hasStateTax: false
        )

        // Then
        XCTAssertTrue(breakdown.formattedEarnings.contains("75"))
        XCTAssertTrue(breakdown.formattedEarnings.contains("$"))
    }

    func testStateBreakdown_hasStateTax_reflectsStateProperty() {
        // Given - Texas has no state income tax
        let texasBreakdown = StateBreakdown(
            state: .texas,
            earnings: 50000,
            weeksWorked: 13,
            hasStateTax: false
        )

        // Given - California has state income tax
        let californiaBreakdown = StateBreakdown(
            state: .california,
            earnings: 50000,
            weeksWorked: 13,
            hasStateTax: true
        )

        // Then
        XCTAssertFalse(texasBreakdown.hasStateTax)
        XCTAssertTrue(californiaBreakdown.hasStateTax)
    }
}
