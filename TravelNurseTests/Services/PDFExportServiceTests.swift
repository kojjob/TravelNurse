//
//  PDFExportServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for PDFExportService - generates professional tax reports
//

import XCTest
import PDFKit
@testable import TravelNurse

// MARK: - Test Data Extension

extension TaxReportData {
    /// Sample data for testing PDF generation
    static var sample: TaxReportData {
        TaxReportData(
            year: 2024,
            userName: "Jane Doe, RN",
            totalIncome: 95000,
            totalExpenses: 12500,
            mileageDeduction: 3500,
            totalMiles: 5223,
            stateBreakdowns: [
                StateBreakdown(state: .california, earnings: 45000, weeksWorked: 13, hasStateTax: true),
                StateBreakdown(state: .texas, earnings: 35000, weeksWorked: 10, hasStateTax: false),
                StateBreakdown(state: .florida, earnings: 15000, weeksWorked: 4, hasStateTax: false)
            ]
        )
    }
}

// MARK: - PDFExportService Tests

@MainActor
final class PDFExportServiceTests: XCTestCase {

    var sut: PDFExportService!
    var testData: TaxReportData!

    override func setUp() {
        super.setUp()
        sut = PDFExportService()
        testData = TaxReportData.sample
    }

    override func tearDown() {
        sut = nil
        testData = nil
        super.tearDown()
    }

    // MARK: - PDF Generation Tests

    func test_generatePDF_returnsNonNilData() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        XCTAssertNotNil(pdfData, "PDF data should not be nil")
    }

    func test_generatePDF_returnsValidPDFData() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        guard let data = pdfData else {
            XCTFail("PDF data should not be nil")
            return
        }

        let pdfDocument = PDFDocument(data: data)
        XCTAssertNotNil(pdfDocument, "Data should be valid PDF format")
    }

    func test_generatePDF_hasAtLeastOnePage() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        guard let data = pdfData,
              let pdfDocument = PDFDocument(data: data) else {
            XCTFail("PDF should be valid")
            return
        }

        XCTAssertGreaterThanOrEqual(pdfDocument.pageCount, 1, "PDF should have at least 1 page")
    }

    func test_generatePDF_containsYearInContent() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        guard let data = pdfData,
              let pdfDocument = PDFDocument(data: data),
              let page = pdfDocument.page(at: 0),
              let text = page.string else {
            XCTFail("PDF should be valid with extractable text")
            return
        }

        XCTAssertTrue(text.contains("\(testData.year)"), "PDF should contain the tax year")
    }

    func test_generatePDF_containsUserName() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        guard let data = pdfData,
              let pdfDocument = PDFDocument(data: data),
              let page = pdfDocument.page(at: 0),
              let text = page.string else {
            XCTFail("PDF should be valid with extractable text")
            return
        }

        XCTAssertTrue(text.contains(testData.userName), "PDF should contain the user name")
    }

    // MARK: - File Export Tests

    func test_exportToFile_createsFileAtPath() async {
        // Given
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_report.pdf")

        // Cleanup before test
        try? FileManager.default.removeItem(at: tempURL)

        // When
        let success = await sut.exportTaxReport(from: testData, to: tempURL)

        // Then
        XCTAssertTrue(success, "Export should succeed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path), "PDF file should exist")

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    func test_exportToFile_createdFileIsValidPDF() async {
        // Given
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_valid.pdf")
        try? FileManager.default.removeItem(at: tempURL)

        // When
        let success = await sut.exportTaxReport(from: testData, to: tempURL)

        // Then
        XCTAssertTrue(success)

        let pdfDocument = PDFDocument(url: tempURL)
        XCTAssertNotNil(pdfDocument, "Exported file should be a valid PDF")
        XCTAssertGreaterThan(pdfDocument?.pageCount ?? 0, 0)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Content Validation Tests

    func test_generatePDF_includesSummarySection() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        guard let data = pdfData,
              let pdfDocument = PDFDocument(data: data) else {
            XCTFail("PDF should be valid")
            return
        }

        // Extract all text from PDF
        var allText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                allText += pageText
            }
        }

        // Should contain summary labels
        XCTAssertTrue(allText.lowercased().contains("income") || allText.lowercased().contains("summary"),
                      "PDF should contain income/summary section")
    }

    func test_generatePDF_includesStateBreakdown() async {
        // When
        let pdfData = await sut.generateTaxReport(from: testData)

        // Then
        guard let data = pdfData,
              let pdfDocument = PDFDocument(data: data) else {
            XCTFail("PDF should be valid")
            return
        }

        var allText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                allText += pageText
            }
        }

        // Should contain at least one state from breakdown
        let containsState = testData.stateBreakdowns.contains { breakdown in
            allText.contains(breakdown.state.rawValue) || allText.contains(breakdown.state.fullName)
        }
        XCTAssertTrue(containsState, "PDF should contain state breakdown information")
    }

    // MARK: - Edge Cases

    func test_generatePDF_withEmptyStateBreakdowns_stillGenerates() async {
        // Given
        let emptyData = TaxReportData(
            year: 2024,
            userName: "Test User",
            totalIncome: 0,
            totalExpenses: 0,
            mileageDeduction: 0,
            totalMiles: 0,
            stateBreakdowns: []
        )

        // When
        let pdfData = await sut.generateTaxReport(from: emptyData)

        // Then
        XCTAssertNotNil(pdfData, "PDF should still generate with empty data")
    }

    func test_generatePDF_withLargeNumbers_handlesCorrectly() async {
        // Given
        let largeData = TaxReportData(
            year: 2024,
            userName: "High Earner, RN",
            totalIncome: 250000,
            totalExpenses: 35000,
            mileageDeduction: 15000,
            totalMiles: 22388,
            stateBreakdowns: [
                StateBreakdown(state: .newYork, earnings: 150000, weeksWorked: 26, hasStateTax: true),
                StateBreakdown(state: .california, earnings: 100000, weeksWorked: 26, hasStateTax: true)
            ]
        )

        // When
        let pdfData = await sut.generateTaxReport(from: largeData)

        // Then
        XCTAssertNotNil(pdfData)

        guard let data = pdfData,
              let pdfDocument = PDFDocument(data: data) else {
            XCTFail("PDF should be valid")
            return
        }

        XCTAssertGreaterThan(pdfDocument.pageCount, 0)
    }

    func test_generatePDF_withSpecialCharactersInName_handlesCorrectly() async {
        // Given
        let specialData = TaxReportData(
            year: 2024,
            userName: "María O'Connor-Smith, RN, BSN",
            totalIncome: 80000,
            totalExpenses: 10000,
            mileageDeduction: 2000,
            totalMiles: 3000,
            stateBreakdowns: []
        )

        // When
        let pdfData = await sut.generateTaxReport(from: specialData)

        // Then
        XCTAssertNotNil(pdfData, "PDF should handle special characters in name")
    }

    // MARK: - Performance Tests

    func test_generatePDF_completesInReasonableTime() async {
        // Given
        let startTime = Date()

        // When
        let _ = await sut.generateTaxReport(from: testData)

        // Then
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 5.0, "PDF generation should complete within 5 seconds")
    }
}

// MARK: - PDF Page Size Tests

@MainActor
final class PDFExportServicePageTests: XCTestCase {

    var sut: PDFExportService!

    override func setUp() {
        super.setUp()
        sut = PDFExportService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_pdfPageSize_isLetterSize() async {
        // Given
        let data = TaxReportData.sample

        // When
        let pdfData = await sut.generateTaxReport(from: data)

        // Then
        guard let pdfDataUnwrapped = pdfData,
              let pdfDocument = PDFDocument(data: pdfDataUnwrapped),
              let page = pdfDocument.page(at: 0) else {
            XCTFail("PDF should be valid")
            return
        }

        let bounds = page.bounds(for: .mediaBox)

        // Letter size is 612 x 792 points
        XCTAssertEqual(bounds.width, 612, accuracy: 1.0, "Width should be letter size")
        XCTAssertEqual(bounds.height, 792, accuracy: 1.0, "Height should be letter size")
    }
}
