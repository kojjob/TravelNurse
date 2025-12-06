//
//  Receipt.swift
//  TravelNurse
//
//  Receipt image and OCR data model
//

import Foundation
import SwiftData

/// Receipt image with OCR-extracted data
@Model
public final class Receipt {
    /// Unique identifier
    public var id: UUID

    /// Image data (stored as Data for SwiftData)
    @Attribute(.externalStorage)
    public var imageData: Data?

    /// Image file path (alternative to storing data)
    public var imagePath: String?

    /// OCR-extracted merchant name
    public var ocrMerchantName: String?

    /// OCR-extracted amount
    public var ocrAmount: Decimal?

    /// OCR-extracted date
    public var ocrDate: Date?

    /// Full OCR text content
    public var ocrFullText: String?

    /// OCR processing status
    public var ocrStatusRaw: String

    /// OCR confidence score (0-1)
    public var ocrConfidence: Double?

    /// Whether OCR results have been verified by user
    public var isVerified: Bool

    /// Creation timestamp
    public var createdAt: Date

    /// Last update timestamp
    public var updatedAt: Date

    // MARK: - Computed Properties

    /// OCR status as enum
    public var ocrStatus: OCRStatus {
        get { OCRStatus(rawValue: ocrStatusRaw) ?? .pending }
        set { ocrStatusRaw = newValue.rawValue }
    }

    /// Whether OCR processing is complete and successful
    public var hasOCRData: Bool {
        ocrStatus == .completed && (ocrMerchantName != nil || ocrAmount != nil)
    }

    /// Formatted OCR confidence percentage
    public var ocrConfidenceFormatted: String? {
        guard let confidence = ocrConfidence else { return nil }
        return "\(Int(confidence * 100))% confidence"
    }

    // MARK: - Initializer

    public init(
        imageData: Data? = nil,
        imagePath: String? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.imagePath = imagePath
        self.ocrStatusRaw = OCRStatus.pending.rawValue
        self.isVerified = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - OCR Status

/// Status of OCR processing for a receipt
public enum OCRStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"

    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
}

// MARK: - OCR Results

extension Receipt {
    /// Update receipt with OCR results
    public func updateWithOCRResults(
        merchantName: String?,
        amount: Decimal?,
        date: Date?,
        fullText: String?,
        confidence: Double
    ) {
        self.ocrMerchantName = merchantName
        self.ocrAmount = amount
        self.ocrDate = date
        self.ocrFullText = fullText
        self.ocrConfidence = confidence
        self.ocrStatus = .completed
        self.updatedAt = Date()
    }

    /// Mark OCR as failed
    public func markOCRFailed() {
        self.ocrStatus = .failed
        self.updatedAt = Date()
    }
}
