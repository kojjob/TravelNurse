//
//  Document.swift
//  TravelNurse
//
//  Document storage model for tax home proof and records
//

import Foundation
import SwiftData

/// Stored document for record-keeping and tax home proof
@Model
public final class Document {
    /// Unique identifier
    public var id: UUID

    /// Document title
    public var title: String

    /// Document description
    public var documentDescription: String?

    /// Document type (raw value)
    public var documentTypeRaw: String

    /// File path or URL
    public var filePath: String?

    /// File data (for small documents)
    @Attribute(.externalStorage)
    public var fileData: Data?

    /// File MIME type
    public var mimeType: String?

    /// File size in bytes
    public var fileSize: Int64?

    /// Associated tax year
    public var taxYear: Int

    /// Category for organization
    public var categoryRaw: String

    /// Tags for searching (comma-separated)
    public var tags: String?

    /// Whether this is a tax home proof document
    public var isTaxHomeProof: Bool

    /// Expiration date (for licenses, certifications)
    public var expirationDate: Date?

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// Document type as enum
    public var documentType: DocumentType {
        get { DocumentType(rawValue: documentTypeRaw) ?? .other }
        set { documentTypeRaw = newValue.rawValue }
    }

    /// Document category as enum
    public var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Whether document is expired
    public var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }

    /// Days until expiration
    public var daysUntilExpiration: Int? {
        guard let expDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
    }

    /// Formatted file size
    public var fileSizeFormatted: String? {
        guard let size = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    /// Array of tags
    public var tagArray: [String] {
        get { tags?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [] }
        set { tags = newValue.joined(separator: ", ") }
    }

    // MARK: - Initializer

    public init(
        title: String,
        documentType: DocumentType,
        category: DocumentCategory,
        isTaxHomeProof: Bool = false,
        taxYear: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.documentTypeRaw = documentType.rawValue
        self.categoryRaw = category.rawValue
        self.isTaxHomeProof = isTaxHomeProof
        self.taxYear = taxYear ?? Calendar.current.component(.year, from: Date())
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Document Types

/// Types of documents that can be stored
public enum DocumentType: String, CaseIterable, Codable, Identifiable {
    case pdf = "pdf"
    case image = "image"
    case scan = "scan"
    case receipt = "receipt"
    case contract = "contract"
    case license = "license"
    case certification = "certification"
    case taxForm = "tax_form"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pdf: return "PDF Document"
        case .image: return "Image"
        case .scan: return "Scanned Document"
        case .receipt: return "Receipt"
        case .contract: return "Contract"
        case .license: return "License"
        case .certification: return "Certification"
        case .taxForm: return "Tax Form"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .scan: return "doc.text.viewfinder"
        case .receipt: return "receipt.fill"
        case .contract: return "doc.text.fill"
        case .license: return "person.text.rectangle.fill"
        case .certification: return "checkmark.seal.fill"
        case .taxForm: return "doc.badge.gearshape.fill"
        case .other: return "doc.fill"
        }
    }
}

// MARK: - Document Categories

/// Categories for document organization
public enum DocumentCategory: String, CaseIterable, Codable, Identifiable {
    case taxHome = "tax_home"
    case assignment = "assignment"
    case licensure = "licensure"
    case expense = "expense"
    case income = "income"
    case insurance = "insurance"
    case personal = "personal"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .taxHome: return "Tax Home Proof"
        case .assignment: return "Assignment Documents"
        case .licensure: return "Licensure & Certifications"
        case .expense: return "Expense Records"
        case .income: return "Income Records"
        case .insurance: return "Insurance"
        case .personal: return "Personal"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .taxHome: return "house.fill"
        case .assignment: return "briefcase.fill"
        case .licensure: return "checkmark.seal.fill"
        case .expense: return "creditcard.fill"
        case .income: return "dollarsign.circle.fill"
        case .insurance: return "shield.fill"
        case .personal: return "person.fill"
        case .other: return "folder.fill"
        }
    }
}
