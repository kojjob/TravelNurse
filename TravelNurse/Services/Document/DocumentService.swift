//
//  DocumentService.swift
//  TravelNurse
//
//  Service for managing document storage and retrieval
//

import Foundation
import SwiftData

// MARK: - Document Statistics

/// Statistics about stored documents
struct DocumentStatistics {
    let totalDocuments: Int
    let taxHomeProofCount: Int
    let expiringWithin30Days: Int
    let documentsByCategory: [DocumentCategory: Int]
    let documentsByType: [DocumentType: Int]
    let totalStorageBytes: Int64
}

// MARK: - Document Service

/// Service for managing document CRUD operations
@MainActor
final class DocumentService {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    /// Creates a new document
    func createDocument(
        title: String,
        documentType: DocumentType,
        category: DocumentCategory,
        description: String? = nil,
        isTaxHomeProof: Bool = false,
        taxYear: Int? = nil,
        expirationDate: Date? = nil,
        fileData: Data? = nil,
        filePath: String? = nil,
        mimeType: String? = nil,
        tags: [String]? = nil
    ) async throws -> Document {
        let document = Document(
            title: title,
            documentType: documentType,
            category: category,
            isTaxHomeProof: isTaxHomeProof,
            taxYear: taxYear
        )

        document.documentDescription = description
        document.expirationDate = expirationDate
        document.fileData = fileData
        document.filePath = filePath
        document.mimeType = mimeType

        if let fileData = fileData {
            document.fileSize = Int64(fileData.count)
        }

        if let tags = tags {
            document.tagArray = tags
        }

        modelContext.insert(document)
        try modelContext.save()

        return document
    }

    // MARK: - Fetch

    /// Fetches all documents sorted by creation date (newest first)
    func fetchAllDocuments() async throws -> [Document] {
        let descriptor = FetchDescriptor<Document>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches documents by category
    func fetchDocuments(category: DocumentCategory) async throws -> [Document] {
        let categoryRaw = category.rawValue
        let predicate = #Predicate<Document> { document in
            document.categoryRaw == categoryRaw
        }
        let descriptor = FetchDescriptor<Document>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches documents by type
    func fetchDocuments(type: DocumentType) async throws -> [Document] {
        let typeRaw = type.rawValue
        let predicate = #Predicate<Document> { document in
            document.documentTypeRaw == typeRaw
        }
        let descriptor = FetchDescriptor<Document>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches tax home proof documents
    func fetchTaxHomeProofDocuments() async throws -> [Document] {
        let predicate = #Predicate<Document> { document in
            document.isTaxHomeProof == true
        }
        let descriptor = FetchDescriptor<Document>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches documents for a specific tax year
    func fetchDocuments(taxYear: Int) async throws -> [Document] {
        let predicate = #Predicate<Document> { document in
            document.taxYear == taxYear
        }
        let descriptor = FetchDescriptor<Document>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches documents expiring within specified days
    func fetchExpiringDocuments(withinDays days: Int) async throws -> [Document] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now)!

        let predicate = #Predicate<Document> { document in
            document.expirationDate != nil &&
            document.expirationDate! > now &&
            document.expirationDate! <= futureDate
        }
        let descriptor = FetchDescriptor<Document>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.expirationDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches expired documents
    func fetchExpiredDocuments() async throws -> [Document] {
        let now = Date()
        let predicate = #Predicate<Document> { document in
            document.expirationDate != nil && document.expirationDate! < now
        }
        let descriptor = FetchDescriptor<Document>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.expirationDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    /// Updates a document's properties
    func updateDocument(
        _ document: Document,
        title: String? = nil,
        description: String? = nil,
        category: DocumentCategory? = nil,
        documentType: DocumentType? = nil,
        isTaxHomeProof: Bool? = nil,
        expirationDate: Date? = nil,
        tags: [String]? = nil
    ) async throws {
        if let title = title {
            document.title = title
        }
        if let description = description {
            document.documentDescription = description
        }
        if let category = category {
            document.category = category
        }
        if let documentType = documentType {
            document.documentType = documentType
        }
        if let isTaxHomeProof = isTaxHomeProof {
            document.isTaxHomeProof = isTaxHomeProof
        }
        if let expirationDate = expirationDate {
            document.expirationDate = expirationDate
        }
        if let tags = tags {
            document.tagArray = tags
        }

        document.updatedAt = Date()
        try modelContext.save()
    }

    /// Updates document file data
    func updateDocumentFile(
        _ document: Document,
        fileData: Data?,
        mimeType: String?
    ) async throws {
        document.fileData = fileData
        document.mimeType = mimeType
        document.fileSize = fileData != nil ? Int64(fileData!.count) : nil
        document.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    /// Deletes a document
    func deleteDocument(_ document: Document) async throws {
        modelContext.delete(document)
        try modelContext.save()
    }

    /// Deletes multiple documents
    func deleteDocuments(_ documents: [Document]) async throws {
        for document in documents {
            modelContext.delete(document)
        }
        try modelContext.save()
    }

    // MARK: - Search

    /// Searches documents by title or tags
    func searchDocuments(query: String) async throws -> [Document] {
        let lowercaseQuery = query.lowercased()
        let allDocuments = try await fetchAllDocuments()

        return allDocuments.filter { document in
            document.title.lowercased().contains(lowercaseQuery) ||
            (document.documentDescription?.lowercased().contains(lowercaseQuery) ?? false) ||
            (document.tags?.lowercased().contains(lowercaseQuery) ?? false)
        }
    }

    // MARK: - Statistics

    /// Gets document statistics
    func getDocumentStatistics() async throws -> DocumentStatistics {
        let allDocuments = try await fetchAllDocuments()
        let expiringDocuments = try await fetchExpiringDocuments(withinDays: 30)

        var byCategory: [DocumentCategory: Int] = [:]
        var byType: [DocumentType: Int] = [:]
        var totalStorage: Int64 = 0
        var taxHomeProofCount = 0

        for document in allDocuments {
            byCategory[document.category, default: 0] += 1
            byType[document.documentType, default: 0] += 1

            if let size = document.fileSize {
                totalStorage += size
            }

            if document.isTaxHomeProof {
                taxHomeProofCount += 1
            }
        }

        return DocumentStatistics(
            totalDocuments: allDocuments.count,
            taxHomeProofCount: taxHomeProofCount,
            expiringWithin30Days: expiringDocuments.count,
            documentsByCategory: byCategory,
            documentsByType: byType,
            totalStorageBytes: totalStorage
        )
    }
}
