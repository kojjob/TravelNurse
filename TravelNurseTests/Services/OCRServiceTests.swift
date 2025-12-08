//
//  OCRServiceTests.swift
//  TravelNurseTests
//
//  Tests for OCRService - TDD approach for receipt text extraction and parsing
//

import XCTest
@testable import TravelNurse

final class OCRServiceTests: XCTestCase {

    var sut: OCRService!

    override func setUp() {
        super.setUp()
        sut = OCRService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - ParseReceiptData Tests

    func test_parseReceiptData_extractsMerchantName_fromFirstLine() {
        // Given
        let receiptText = """
        Walgreens Store #1234
        123 Main Street
        City, State 12345
        Date: 01/15/2024
        Total: $25.99
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.merchantName)
        XCTAssertEqual(result.merchantName, "Walgreens Store #1234")
    }

    func test_parseReceiptData_extractsMerchantName_withBusinessIndicators() {
        // Given
        let receiptText = """
        CVS Pharmacy Inc.
        Your Receipt
        Total: $15.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertEqual(result.merchantName, "CVS Pharmacy Inc.")
    }

    func test_parseReceiptData_extractsTotalAmount_withDollarSign() {
        // Given
        let receiptText = """
        Store Name
        Item 1    $5.99
        Item 2    $3.99
        Subtotal  $9.98
        Tax       $0.80
        Total: $10.78
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.amount)
        XCTAssertEqual(result.amount, Decimal(string: "10.78"))
    }

    func test_parseReceiptData_extractsTotalAmount_withGrandTotal() {
        // Given
        let receiptText = """
        Store Name
        Grand Total: $45.99
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertEqual(result.amount, Decimal(string: "45.99"))
    }

    func test_parseReceiptData_extractsTotalAmount_withAmountDue() {
        // Given
        let receiptText = """
        Store Name
        Amount Due: $123.45
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertEqual(result.amount, Decimal(string: "123.45"))
    }

    func test_parseReceiptData_extractsTotalAmount_fallsBackToLargestAmount() {
        // Given - no "total" keyword, should find largest amount
        let receiptText = """
        Store Name
        Coffee    $4.50
        Pastry    $3.25
        $7.75
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.amount)
        XCTAssertEqual(result.amount, Decimal(string: "7.75"))
    }

    func test_parseReceiptData_extractsDate_slashFormat() {
        // Given
        let receiptText = """
        Store Name
        Date: 01/15/2024
        Total: $10.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: result.date!)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.year, 2024)
    }

    func test_parseReceiptData_extractsDate_dashFormat() {
        // Given
        let receiptText = """
        Store Name
        03-22-2024
        Total: $10.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: result.date!)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 22)
        XCTAssertEqual(components.year, 2024)
    }

    func test_parseReceiptData_extractsDate_isoFormat() {
        // Given
        let receiptText = """
        Store Name
        2024-06-15
        Total: $10.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: result.date!)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.year, 2024)
    }

    func test_parseReceiptData_extractsDate_writtenFormat() {
        // Given
        let receiptText = """
        Store Name
        Jan 15, 2024
        Total: $10.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .year], from: result.date!)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.year, 2024)
    }

    func test_parseReceiptData_extractsLineItems_withPrices() {
        // Given
        let receiptText = """
        Target Store
        Milk        $3.99
        Bread       $2.49
        Eggs        $4.99
        Subtotal    $11.47
        Tax         $0.92
        Total       $12.39
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertEqual(result.items.count, 3)
        XCTAssertTrue(result.items.contains { $0.contains("Milk") && $0.contains("3.99") })
        XCTAssertTrue(result.items.contains { $0.contains("Bread") && $0.contains("2.49") })
        XCTAssertTrue(result.items.contains { $0.contains("Eggs") && $0.contains("4.99") })
    }

    func test_parseReceiptData_excludesTotalAndTaxFromItems() {
        // Given
        let receiptText = """
        Store
        Item A      $5.00
        Subtotal    $5.00
        Tax         $0.40
        Total       $5.40
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertEqual(result.items.count, 1)
        XCTAssertTrue(result.items.first?.contains("Item A") ?? false)
        XCTAssertFalse(result.items.contains { $0.lowercased().contains("total") })
        XCTAssertFalse(result.items.contains { $0.lowercased().contains("tax") })
    }

    func test_parseReceiptData_calculatesConfidence_allFieldsFound() {
        // Given
        let receiptText = """
        Walgreens Store
        Date: 01/15/2024
        Item 1    $5.00
        Total: $5.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        // Merchant (0.3) + Amount (0.4) + Date (0.2) + Items (0.1) = 1.0
        XCTAssertEqual(result.confidence, 1.0, accuracy: 0.01)
    }

    func test_parseReceiptData_calculatesConfidence_partialFields() {
        // Given - only merchant and amount
        let receiptText = """
        Store Name
        Total: $25.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        // Merchant (0.3) + Amount (0.4) = 0.7
        XCTAssertEqual(result.confidence, 0.7, accuracy: 0.01)
    }

    func test_parseReceiptData_calculatesConfidence_noFieldsFound() {
        // Given - no parseable data
        let receiptText = """
        Random text
        More random text
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        // Only merchant name might be extracted (first line)
        XCTAssertLessThanOrEqual(result.confidence, 0.3)
    }

    func test_parseReceiptData_handlesEmptyString() {
        // Given
        let receiptText = ""

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNil(result.merchantName)
        XCTAssertNil(result.amount)
        XCTAssertNil(result.date)
        XCTAssertTrue(result.items.isEmpty)
        XCTAssertEqual(result.confidence, 0.0)
    }

    // MARK: - Real Receipt Scenarios

    func test_parseReceiptData_realGasStationReceipt() {
        // Given - typical gas station receipt
        let receiptText = """
        Shell Gas Station
        1234 Highway Ave
        Austin, TX 78701

        Date: 12/05/2024

        Regular Unleaded    $45.23

        Total: $45.23

        Thank you for your business!
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.merchantName)
        XCTAssertTrue(result.merchantName?.contains("Shell") ?? false)
        XCTAssertEqual(result.amount, Decimal(string: "45.23"))
        XCTAssertNotNil(result.date)
    }

    func test_parseReceiptData_realPharmacyReceipt() {
        // Given - typical pharmacy receipt
        let receiptText = """
        CVS Pharmacy
        Store #5678

        01/20/2024 3:45 PM

        Medication         $12.99
        First Aid Kit      $8.49
        Vitamins           $15.99

        Subtotal           $37.47
        Tax                $3.00
        Grand Total        $40.47
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.merchantName)
        XCTAssertTrue(result.merchantName?.contains("CVS") ?? false)
        XCTAssertEqual(result.amount, Decimal(string: "40.47"))
        XCTAssertEqual(result.items.count, 3)
    }

    func test_parseReceiptData_realHotelReceipt() {
        // Given - typical hotel receipt
        let receiptText = """
        Hilton Hotel
        Downtown Location

        Invoice Date: Feb 15, 2024

        Room Charge        $149.00
        Room Tax           $18.63

        Amount Due: $167.63

        Thank you for staying with us!
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.merchantName)
        XCTAssertTrue(result.merchantName?.contains("Hilton") ?? false)
        XCTAssertEqual(result.amount, Decimal(string: "167.63"))
        XCTAssertNotNil(result.date)
    }

    // MARK: - ExtractText Error Handling Tests

    func test_extractText_throwsInvalidImage_forNilCGImage() async {
        // Given - create an image that returns nil cgImage
        // Note: A 0x0 UIImage will have nil cgImage
        let emptyImage = UIImage()

        // When/Then
        do {
            _ = try await sut.extractText(from: emptyImage)
            XCTFail("Expected OCRError.invalidImage to be thrown")
        } catch let error as OCRError {
            switch error {
            case .invalidImage:
                // Expected
                XCTAssertEqual(error.errorDescription, "Unable to process the image. Please try again with a clearer photo.")
            default:
                XCTFail("Expected OCRError.invalidImage but got \(error)")
            }
        } catch {
            XCTFail("Expected OCRError but got \(error)")
        }
    }

    // MARK: - OCRError Tests

    func test_ocrError_invalidImage_hasCorrectDescription() {
        // Given
        let error = OCRError.invalidImage

        // Then
        XCTAssertEqual(error.errorDescription, "Unable to process the image. Please try again with a clearer photo.")
    }

    func test_ocrError_noTextFound_hasCorrectDescription() {
        // Given
        let error = OCRError.noTextFound

        // Then
        XCTAssertEqual(error.errorDescription, "No text was detected in the image. Please ensure the receipt is clearly visible.")
    }

    func test_ocrError_recognitionFailed_includesMessage() {
        // Given
        let error = OCRError.recognitionFailed("Connection timeout")

        // Then
        XCTAssertEqual(error.errorDescription, "Text recognition failed: Connection timeout")
    }

    func test_ocrError_parsingFailed_hasCorrectDescription() {
        // Given
        let error = OCRError.parsingFailed

        // Then
        XCTAssertEqual(error.errorDescription, "Unable to parse receipt data from the extracted text.")
    }

    // MARK: - OCRResult Tests

    func test_ocrResult_storesAllProperties() {
        // Given
        let observation = OCRResult.RecognizedTextObservation(
            text: "Test text",
            confidence: 0.95,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 20)
        )

        // When
        let result = OCRResult(
            fullText: "Full text content",
            confidence: 0.9,
            observations: [observation]
        )

        // Then
        XCTAssertEqual(result.fullText, "Full text content")
        XCTAssertEqual(result.confidence, 0.9)
        XCTAssertEqual(result.observations.count, 1)
        XCTAssertEqual(result.observations.first?.text, "Test text")
        XCTAssertEqual(result.observations.first?.confidence, 0.95)
    }

    // MARK: - ParsedReceiptData Tests

    func test_parsedReceiptData_defaultInitializer() {
        // When
        let data = ParsedReceiptData()

        // Then
        XCTAssertNil(data.merchantName)
        XCTAssertNil(data.amount)
        XCTAssertNil(data.date)
        XCTAssertTrue(data.items.isEmpty)
        XCTAssertEqual(data.confidence, 0.0)
    }

    func test_parsedReceiptData_customInitializer() {
        // Given
        let testDate = Date()

        // When
        let data = ParsedReceiptData(
            merchantName: "Test Store",
            amount: Decimal(string: "99.99"),
            date: testDate,
            items: ["Item 1", "Item 2"],
            confidence: 0.85
        )

        // Then
        XCTAssertEqual(data.merchantName, "Test Store")
        XCTAssertEqual(data.amount, Decimal(string: "99.99"))
        XCTAssertEqual(data.date, testDate)
        XCTAssertEqual(data.items, ["Item 1", "Item 2"])
        XCTAssertEqual(data.confidence, 0.85)
    }

    // MARK: - Edge Cases

    func test_parseReceiptData_handlesSpecialCharacters() {
        // Given
        let receiptText = """
        McDonald's Restaurant
        #1234 @ Main St.
        Total: $15.99
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.merchantName)
        XCTAssertNotNil(result.amount)
    }

    func test_parseReceiptData_handlesMultipleDollarAmounts() {
        // Given
        let receiptText = """
        Store Name
        Item     $5.00
        Item     $10.00
        Item     $3.00
        Tax      $1.44
        Total:   $19.44
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        // Should find the total, not individual items
        XCTAssertEqual(result.amount, Decimal(string: "19.44"))
    }

    func test_parseReceiptData_handlesNoDecimalAmounts() {
        // Given
        let receiptText = """
        Store
        Total: $50
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertEqual(result.amount, Decimal(50))
    }

    func test_parseReceiptData_handlesTwoDigitYear() {
        // Given
        let receiptText = """
        Store
        Date: 1/5/24
        Total: $10.00
        """

        // When
        let result = sut.parseReceiptData(from: receiptText)

        // Then
        XCTAssertNotNil(result.date)
        let components = Calendar.current.dateComponents([.year], from: result.date!)
        XCTAssertEqual(components.year, 2024)
    }
}
