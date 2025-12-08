//
//  DocumentServiceTests.swift
//  TravelNurseTests
//
//  TDD tests for DocumentService
//

import XCTest
import SwiftData
@testable import TravelNurse

@MainActor
final class DocumentServiceTests: XCTestCase {

    var sut: DocumentService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([Document.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
        sut = DocumentService(modelContext: modelContext)
    }

    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Create Tests

    func testCreateDocument() async throws {
        // Given
        let title = "W-2 Form 2024"
        let type = DocumentType.taxForm
        let category = DocumentCategory.income

        // When
        let document = try await sut.createDocument(
            title: title,
            documentType: type,
            category: category,
            isTaxHomeProof: false
        )

        // Then
        XCTAssertEqual(document.title, title)
        XCTAssertEqual(document.documentType, type)
        XCTAssertEqual(document.category, category)
        XCTAssertFalse(document.isTaxHomeProof)
        XCTAssertNotNil(document.id)
    }

    func testCreateTaxHomeProofDocument() async throws {
        // Given
        let title = "Utility Bill - March 2024"
        let type = DocumentType.scan
        let category = DocumentCategory.taxHome

        // When
        let document = try await sut.createDocument(
            title: title,
            documentType: type,
            category: category,
            isTaxHomeProof: true
        )

        // Then
        XCTAssertTrue(document.isTaxHomeProof)
        XCTAssertEqual(document.category, .taxHome)
    }

    func testCreateDocumentWithExpiration() async throws {
        // Given
        let title = "RN License - California"
        let expirationDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

        // When
        let document = try await sut.createDocument(
            title: title,
            documentType: .license,
            category: .licensure,
            expirationDate: expirationDate
        )

        // Then
        XCTAssertEqual(document.expirationDate, expirationDate)
        XCTAssertFalse(document.isExpired)
    }

    func testCreateDocumentWithFileData() async throws {
        // Given
        let title = "Contract Scan"
        let fileData = "Test PDF content".data(using: .utf8)!
        let mimeType = "application/pdf"

        // When
        let document = try await sut.createDocument(
            title: title,
            documentType: .contract,
            category: .assignment,
            fileData: fileData,
            mimeType: mimeType
        )

        // Then
        XCTAssertEqual(document.fileData, fileData)
        XCTAssertEqual(document.mimeType, mimeType)
        XCTAssertEqual(document.fileSize, Int64(fileData.count))
    }

    // MARK: - Fetch Tests

    func testFetchAllDocuments() async throws {
        // Given
        _ = try await sut.createDocument(title: "Doc 1", documentType: .pdf, category: .other)
        _ = try await sut.createDocument(title: "Doc 2", documentType: .image, category: .personal)
        _ = try await sut.createDocument(title: "Doc 3", documentType: .receipt, category: .expense)

        // When
        let documents = try await sut.fetchAllDocuments()

        // Then
        XCTAssertEqual(documents.count, 3)
    }

    func testFetchDocumentsByCategory() async throws {
        // Given
        _ = try await sut.createDocument(title: "Tax Home 1", documentType: .scan, category: .taxHome, isTaxHomeProof: true)
        _ = try await sut.createDocument(title: "Tax Home 2", documentType: .image, category: .taxHome, isTaxHomeProof: true)
        _ = try await sut.createDocument(title: "Other Doc", documentType: .pdf, category: .other)

        // When
        let taxHomeDocuments = try await sut.fetchDocuments(category: .taxHome)

        // Then
        XCTAssertEqual(taxHomeDocuments.count, 2)
        XCTAssertTrue(taxHomeDocuments.allSatisfy { $0.category == .taxHome })
    }

    func testFetchDocumentsByType() async throws {
        // Given
        _ = try await sut.createDocument(title: "License 1", documentType: .license, category: .licensure)
        _ = try await sut.createDocument(title: "License 2", documentType: .license, category: .licensure)
        _ = try await sut.createDocument(title: "Contract", documentType: .contract, category: .assignment)

        // When
        let licenses = try await sut.fetchDocuments(type: .license)

        // Then
        XCTAssertEqual(licenses.count, 2)
        XCTAssertTrue(licenses.allSatisfy { $0.documentType == .license })
    }

    func testFetchTaxHomeProofDocuments() async throws {
        // Given
        _ = try await sut.createDocument(title: "Proof 1", documentType: .scan, category: .taxHome, isTaxHomeProof: true)
        _ = try await sut.createDocument(title: "Proof 2", documentType: .image, category: .taxHome, isTaxHomeProof: true)
        _ = try await sut.createDocument(title: "Not Proof", documentType: .pdf, category: .taxHome, isTaxHomeProof: false)

        // When
        let proofDocuments = try await sut.fetchTaxHomeProofDocuments()

        // Then
        XCTAssertEqual(proofDocuments.count, 2)
        XCTAssertTrue(proofDocuments.allSatisfy { $0.isTaxHomeProof })
    }

    func testFetchDocumentsByTaxYear() async throws {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())
        _ = try await sut.createDocument(title: "2024 Doc", documentType: .taxForm, category: .income, taxYear: currentYear)
        _ = try await sut.createDocument(title: "2023 Doc", documentType: .taxForm, category: .income, taxYear: currentYear - 1)

        // When
        let currentYearDocs = try await sut.fetchDocuments(taxYear: currentYear)

        // Then
        XCTAssertEqual(currentYearDocs.count, 1)
        XCTAssertEqual(currentYearDocs.first?.taxYear, currentYear)
    }

    func testFetchExpiringDocuments() async throws {
        // Given
        let soon = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let later = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let past = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        _ = try await sut.createDocument(title: "Expiring Soon", documentType: .license, category: .licensure, expirationDate: soon)
        _ = try await sut.createDocument(title: "Expiring Later", documentType: .certification, category: .licensure, expirationDate: later)
        _ = try await sut.createDocument(title: "Already Expired", documentType: .license, category: .licensure, expirationDate: past)

        // When
        let expiringIn30Days = try await sut.fetchExpiringDocuments(withinDays: 30)

        // Then
        XCTAssertEqual(expiringIn30Days.count, 1)
        XCTAssertEqual(expiringIn30Days.first?.title, "Expiring Soon")
    }

    // MARK: - Update Tests

    func testUpdateDocument() async throws {
        // Given
        let document = try await sut.createDocument(
            title: "Original Title",
            documentType: .pdf,
            category: .other
        )
        let originalUpdatedAt = document.updatedAt

        // Small delay to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        try await sut.updateDocument(
            document,
            title: "Updated Title",
            description: "New description"
        )

        // Then
        XCTAssertEqual(document.title, "Updated Title")
        XCTAssertEqual(document.documentDescription, "New description")
        XCTAssertGreaterThan(document.updatedAt, originalUpdatedAt)
    }

    func testUpdateDocumentTags() async throws {
        // Given
        let document = try await sut.createDocument(
            title: "Tagged Doc",
            documentType: .receipt,
            category: .expense
        )

        // When
        try await sut.updateDocument(document, tags: ["travel", "deductible", "2024"])

        // Then
        XCTAssertEqual(document.tagArray, ["travel", "deductible", "2024"])
    }

    // MARK: - Delete Tests

    func testDeleteDocument() async throws {
        // Given
        let document = try await sut.createDocument(
            title: "To Delete",
            documentType: .pdf,
            category: .other
        )
        let documentId = document.id

        // When
        try await sut.deleteDocument(document)

        // Then
        let allDocuments = try await sut.fetchAllDocuments()
        XCTAssertFalse(allDocuments.contains { $0.id == documentId })
    }

    func testDeleteMultipleDocuments() async throws {
        // Given
        let doc1 = try await sut.createDocument(title: "Delete 1", documentType: .pdf, category: .other)
        let doc2 = try await sut.createDocument(title: "Delete 2", documentType: .pdf, category: .other)
        _ = try await sut.createDocument(title: "Keep", documentType: .pdf, category: .other)

        // When
        try await sut.deleteDocuments([doc1, doc2])

        // Then
        let remaining = try await sut.fetchAllDocuments()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.title, "Keep")
    }

    // MARK: - Search Tests

    func testSearchDocumentsByTitle() async throws {
        // Given
        _ = try await sut.createDocument(title: "California RN License", documentType: .license, category: .licensure)
        _ = try await sut.createDocument(title: "Texas RN License", documentType: .license, category: .licensure)
        _ = try await sut.createDocument(title: "W-2 Form", documentType: .taxForm, category: .income)

        // When
        let results = try await sut.searchDocuments(query: "License")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.title.contains("License") })
    }

    func testSearchDocumentsByTags() async throws {
        // Given
        let doc1 = try await sut.createDocument(title: "Doc 1", documentType: .receipt, category: .expense)
        try await sut.updateDocument(doc1, tags: ["travel", "hotel"])

        let doc2 = try await sut.createDocument(title: "Doc 2", documentType: .receipt, category: .expense)
        try await sut.updateDocument(doc2, tags: ["food", "meals"])

        // When
        let results = try await sut.searchDocuments(query: "travel")

        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Doc 1")
    }

    // MARK: - Statistics Tests

    func testGetDocumentStatistics() async throws {
        // Given
        _ = try await sut.createDocument(title: "License", documentType: .license, category: .licensure)
        _ = try await sut.createDocument(title: "Tax Home 1", documentType: .scan, category: .taxHome, isTaxHomeProof: true)
        _ = try await sut.createDocument(title: "Tax Home 2", documentType: .image, category: .taxHome, isTaxHomeProof: true)
        _ = try await sut.createDocument(title: "Receipt", documentType: .receipt, category: .expense)

        // When
        let stats = try await sut.getDocumentStatistics()

        // Then
        XCTAssertEqual(stats.totalDocuments, 4)
        XCTAssertEqual(stats.taxHomeProofCount, 2)
        XCTAssertEqual(stats.documentsByCategory[.licensure], 1)
        XCTAssertEqual(stats.documentsByCategory[.taxHome], 2)
        XCTAssertEqual(stats.documentsByCategory[.expense], 1)
    }

    func testGetDocumentStatisticsWithExpiring() async throws {
        // Given
        let soon = Calendar.current.date(byAdding: .day, value: 20, to: Date())!
        _ = try await sut.createDocument(title: "Expiring License", documentType: .license, category: .licensure, expirationDate: soon)
        _ = try await sut.createDocument(title: "Regular Doc", documentType: .pdf, category: .other)

        // When
        let stats = try await sut.getDocumentStatistics()

        // Then
        XCTAssertEqual(stats.expiringWithin30Days, 1)
    }
}

// MARK: - Document Model Tests

final class DocumentModelTests: XCTestCase {

    func testDocumentIsExpired() {
        // Given
        let expiredDoc = Document(title: "Expired", documentType: .license, category: .licensure)
        expiredDoc.expirationDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())

        let validDoc = Document(title: "Valid", documentType: .license, category: .licensure)
        validDoc.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())

        let noExpirationDoc = Document(title: "No Expiration", documentType: .pdf, category: .other)

        // Then
        XCTAssertTrue(expiredDoc.isExpired)
        XCTAssertFalse(validDoc.isExpired)
        XCTAssertFalse(noExpirationDoc.isExpired)
    }

    func testDaysUntilExpiration() {
        // Given
        let doc = Document(title: "Test", documentType: .license, category: .licensure)
        doc.expirationDate = Calendar.current.date(byAdding: .day, value: 45, to: Date())

        // Then
        XCTAssertNotNil(doc.daysUntilExpiration)
        XCTAssertEqual(doc.daysUntilExpiration!, 45, accuracy: 1)
    }

    func testFileSizeFormatted() {
        // Given
        let doc = Document(title: "Test", documentType: .pdf, category: .other)
        doc.fileSize = 1_500_000 // ~1.5 MB

        // Then
        XCTAssertNotNil(doc.fileSizeFormatted)
        XCTAssertTrue(doc.fileSizeFormatted!.contains("MB") || doc.fileSizeFormatted!.contains("1"))
    }

    func testTagArray() {
        // Given
        let doc = Document(title: "Test", documentType: .pdf, category: .other)

        // When
        doc.tagArray = ["travel", "nursing", "2024"]

        // Then
        XCTAssertEqual(doc.tagArray, ["travel", "nursing", "2024"])
        XCTAssertEqual(doc.tags, "travel, nursing, 2024")
    }

    func testDocumentTypeProperties() {
        XCTAssertEqual(DocumentType.license.displayName, "License")
        XCTAssertEqual(DocumentType.license.iconName, "person.text.rectangle.fill")
        XCTAssertEqual(DocumentType.taxForm.displayName, "Tax Form")
    }

    func testDocumentCategoryProperties() {
        XCTAssertEqual(DocumentCategory.taxHome.displayName, "Tax Home Proof")
        XCTAssertEqual(DocumentCategory.taxHome.iconName, "house.fill")
        XCTAssertEqual(DocumentCategory.licensure.displayName, "Licensure & Certifications")
    }
}
