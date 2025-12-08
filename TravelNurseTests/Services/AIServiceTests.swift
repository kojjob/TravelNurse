//
//  AIServiceTests.swift
//  TravelNurseTests
//
//  Tests for AI services - categorization, natural language, tax assistant
//

import XCTest
@testable import TravelNurse

final class ExpenseCategorizationTests: XCTestCase {

    // MARK: - Expense Categorization Tests

    var categorizationService: ExpenseCategorizationService!

    override func setUp() {
        super.setUp()
        categorizationService = ExpenseCategorizationService()
    }

    override func tearDown() {
        categorizationService = nil
        super.tearDown()
    }

    // MARK: - Meal Categorization

    func testCategorizeMealExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Lunch",
            merchant: "Chipotle",
            amount: 15.50
        )

        XCTAssertEqual(prediction.category, .meals)
        XCTAssertGreaterThan(prediction.confidence, 0.5)
        XCTAssertTrue(prediction.isDeductible)
    }

    func testCategorizeRestaurantExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Dinner with colleague",
            merchant: "Olive Garden",
            amount: 45.00
        )

        XCTAssertEqual(prediction.category, .meals)
        XCTAssertTrue(prediction.isDeductible)
        XCTAssertNotNil(prediction.deductionReason)
    }

    func testCategorizeCoffeeExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Morning coffee",
            merchant: "Starbucks",
            amount: 6.50
        )

        XCTAssertEqual(prediction.category, .meals)
    }

    // MARK: - Transportation Categorization

    func testCategorizeUberExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Ride to hospital",
            merchant: "Uber",
            amount: 25.00
        )

        XCTAssertEqual(prediction.category, .transportation)
        XCTAssertTrue(prediction.isDeductible)
    }

    func testCategorizeGasExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Gas fill up",
            merchant: "Shell",
            amount: 55.00
        )

        XCTAssertEqual(prediction.category, .transportation)
    }

    func testCategorizeParkingExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Hospital parking garage",
            merchant: nil,
            amount: 15.00
        )

        XCTAssertEqual(prediction.category, .transportation)
    }

    // MARK: - Medical Supplies Categorization

    func testCategorizeScrubsExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "New scrubs for work",
            merchant: "FIGS",
            amount: 120.00
        )

        XCTAssertEqual(prediction.category, .medicalSupplies)
        XCTAssertTrue(prediction.isDeductible)
    }

    func testCategorizeStethoscopeExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Littmann stethoscope",
            merchant: nil,
            amount: 200.00
        )

        XCTAssertEqual(prediction.category, .medicalSupplies)
    }

    // MARK: - Education Categorization

    func testCategorizeCEUExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "CEU continuing education course",
            merchant: nil,
            amount: 99.00
        )

        XCTAssertEqual(prediction.category, .education)
        XCTAssertTrue(prediction.isDeductible)
    }

    func testCategorizeCertificationExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "ACLS certification renewal",
            merchant: "American Heart Association",
            amount: 175.00
        )

        XCTAssertEqual(prediction.category, .education)
    }

    // MARK: - Lodging Categorization

    func testCategorizeHotelExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Weekly stay",
            merchant: "Marriott",
            amount: 800.00
        )

        XCTAssertEqual(prediction.category, .lodging)
        XCTAssertTrue(prediction.isDeductible)
    }

    func testCategorizeAirbnbExpense() async throws {
        let prediction = try await categorizationService.categorizeExpense(
            description: "Monthly housing",
            merchant: "Airbnb",
            amount: 2500.00
        )

        XCTAssertEqual(prediction.category, .lodging)
    }

    // MARK: - Batch Categorization

    func testBatchCategorization() async throws {
        let expenses = [
            ExpenseInput(id: UUID(), description: "Lunch", merchant: "Panera", amount: 15.00, date: nil),
            ExpenseInput(id: UUID(), description: "Gas", merchant: "Chevron", amount: 50.00, date: nil),
            ExpenseInput(id: UUID(), description: "Scrubs", merchant: "Cherokee", amount: 80.00, date: nil)
        ]

        let predictions = try await categorizationService.categorizeExpenses(expenses)

        XCTAssertEqual(predictions.count, 3)
        XCTAssertEqual(predictions[0].category, .meals)
        XCTAssertEqual(predictions[1].category, .transportation)
        XCTAssertEqual(predictions[2].category, .medicalSupplies)
    }
}

// MARK: - Natural Language Parser Tests

final class NaturalLanguageParserTests: XCTestCase {

    var parser: NaturalLanguageParserService!

    override func setUp() {
        super.setUp()
        parser = NaturalLanguageParserService()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Expense Parsing

    func testParseSimpleExpense() async throws {
        let result = try await parser.parseExpenseFromText("Add $45 for lunch at Chipotle")

        XCTAssertEqual(result.amount, 45)
        XCTAssertEqual(result.merchant, "Chipotle")
        XCTAssertEqual(result.category, .meals)
        XCTAssertTrue(result.isComplete)
    }

    func testParseExpenseWithDecimal() async throws {
        let result = try await parser.parseExpenseFromText("Spent $23.50 at Starbucks")

        XCTAssertEqual(result.amount, Decimal(string: "23.50"))
        XCTAssertEqual(result.merchant, "Starbucks")
    }

    func testParseExpenseWithDollarsWord() async throws {
        let result = try await parser.parseExpenseFromText("Paid 50 dollars for gas at Shell")

        XCTAssertEqual(result.amount, 50)
        XCTAssertEqual(result.merchant, "Shell")
        XCTAssertEqual(result.category, .transportation)
    }

    func testParseExpenseWithToday() async throws {
        let result = try await parser.parseExpenseFromText("$15 lunch today at Panera")

        XCTAssertEqual(result.amount, 15)
        XCTAssertNotNil(result.date)

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInToday(result.date!))
    }

    func testParseExpenseWithYesterday() async throws {
        let result = try await parser.parseExpenseFromText("Yesterday I spent $30 on dinner")

        XCTAssertEqual(result.amount, 30)
        XCTAssertNotNil(result.date)

        let calendar = Calendar.current
        XCTAssertTrue(calendar.isDateInYesterday(result.date!))
    }

    // MARK: - Mileage Parsing

    func testParseSimpleMileage() async throws {
        let result = try await parser.parseMileageFromText("Log 23 miles to the hospital")

        XCTAssertEqual(result.miles, 23)
        XCTAssertTrue(result.isComplete)
    }

    func testParseMileageWithLocations() async throws {
        let result = try await parser.parseMileageFromText("Drove from home to the hospital")

        XCTAssertEqual(result.startLocation, "home")
        XCTAssertNotNil(result.endLocation)
    }

    func testParseMileageWithDecimal() async throws {
        let result = try await parser.parseMileageFromText("15.5 miles for work")

        XCTAssertEqual(result.miles, 15.5)
        XCTAssertEqual(result.purpose, "Work")
    }

    // MARK: - Edge Cases

    func testParseEmptyString() async throws {
        let result = try await parser.parseExpenseFromText("")

        XCTAssertNil(result.amount)
        XCTAssertFalse(result.isComplete)
        XCTAssertLessThan(result.confidence, 0.3)
    }

    func testParseNoAmount() async throws {
        let result = try await parser.parseExpenseFromText("Lunch at McDonalds")

        XCTAssertNil(result.amount)
        XCTAssertEqual(result.merchant, "McDonalds")
        XCTAssertFalse(result.isComplete)
    }
}

// MARK: - Tax Assistant Tests

final class TaxAssistantTests: XCTestCase {

    var assistant: TaxAssistantService!
    var context: TaxAssistantContext!

    override func setUp() {
        super.setUp()
        assistant = TaxAssistantService()
        context = TaxAssistantContext(
            taxYear: 2024,
            taxHomeState: .texas,
            hasMultipleStates: false,
            ytdIncome: 75000,
            ytdDeductions: 5000
        )
    }

    override func tearDown() {
        assistant = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Tax Home Questions

    func testTaxHomeQuestion() async throws {
        let response = try await assistant.sendMessage(
            "What is a tax home?",
            context: context
        )

        XCTAssertTrue(response.message.contains("tax home") || response.message.contains("Tax Home"))
        XCTAssertGreaterThan(response.confidence, 0.8)
        XCTAssertNotNil(response.disclaimer)
    }

    func testTaxHomeRequirements() async throws {
        let response = try await assistant.sendMessage(
            "What do I need to maintain my tax home?",
            context: context
        )

        XCTAssertFalse(response.suggestions.isEmpty)
    }

    // MARK: - Stipend Questions

    func testStipendQuestion() async throws {
        let response = try await assistant.sendMessage(
            "Are my stipends taxable?",
            context: context
        )

        XCTAssertTrue(response.message.lowercased().contains("stipend"))
    }

    // MARK: - Deduction Questions

    func testDeductionQuestion() async throws {
        let response = try await assistant.sendMessage(
            "What expenses can I deduct?",
            context: context
        )

        XCTAssertTrue(response.message.lowercased().contains("deduct"))
        XCTAssertFalse(response.relatedTopics.isEmpty)
    }

    // MARK: - Tax Tips

    func testGetTaxTips() async throws {
        let tips = try await assistant.getTaxTips(for: context)

        XCTAssertFalse(tips.isEmpty)
        // Tips should be sorted by priority
        if tips.count > 1 {
            XCTAssertGreaterThanOrEqual(tips[0].priority, tips[1].priority)
        }
    }

    func testTaxTipsForNoTaxHome() async throws {
        let noHomeContext = TaxAssistantContext(
            taxYear: 2024,
            taxHomeState: nil,
            hasMultipleStates: false,
            ytdIncome: 50000,
            ytdDeductions: 2000
        )

        let tips = try await assistant.getTaxTips(for: noHomeContext)

        // Should include a tip about setting up tax home
        let hasTaxHomeTip = tips.contains { $0.title.lowercased().contains("tax home") }
        XCTAssertTrue(hasTaxHomeTip)
    }

    func testTaxTipsForMultiState() async throws {
        let multiStateContext = TaxAssistantContext(
            taxYear: 2024,
            taxHomeState: .texas,
            hasMultipleStates: true,
            ytdIncome: 80000,
            ytdDeductions: 6000
        )

        let tips = try await assistant.getTaxTips(for: multiStateContext)

        // Should include a tip about multi-state filing
        let hasMultiStateTip = tips.contains { $0.category == .warning }
        XCTAssertTrue(hasMultiStateTip)
    }

    // MARK: - Unknown Questions

    func testUnknownQuestion() async throws {
        let response = try await assistant.sendMessage(
            "What is the meaning of life?",
            context: context
        )

        XCTAssertLessThan(response.confidence, 0.7)
        XCTAssertFalse(response.suggestions.isEmpty) // Should offer suggestions
    }
}
