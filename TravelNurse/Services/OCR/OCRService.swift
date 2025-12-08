//
//  OCRService.swift
//  TravelNurse
//
//  Vision-based OCR service for receipt text extraction
//

import Foundation
import Vision
import UIKit

/// Protocol for OCR processing
protocol OCRServiceProtocol {
    func extractText(from image: UIImage) async throws -> OCRResult
    func parseReceiptData(from text: String) -> ParsedReceiptData
}

/// Result of OCR text extraction
struct OCRResult {
    let fullText: String
    let confidence: Double
    let observations: [RecognizedTextObservation]

    struct RecognizedTextObservation {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
    }
}

/// Parsed receipt data extracted from OCR text
struct ParsedReceiptData {
    var merchantName: String?
    var amount: Decimal?
    var date: Date?
    var items: [String]
    var confidence: Double

    init(merchantName: String? = nil, amount: Decimal? = nil, date: Date? = nil, items: [String] = [], confidence: Double = 0) {
        self.merchantName = merchantName
        self.amount = amount
        self.date = date
        self.items = items
        self.confidence = confidence
    }
}

/// Vision-based OCR service implementation
final class OCRService: OCRServiceProtocol {

    // MARK: - Text Extraction

    func extractText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let recognizedObservations = observations.compactMap { observation -> OCRResult.RecognizedTextObservation? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRResult.RecognizedTextObservation(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                let fullText = recognizedObservations.map { $0.text }.joined(separator: "\n")
                let averageConfidence = recognizedObservations.isEmpty ? 0 :
                    Double(recognizedObservations.reduce(0) { $0 + $1.confidence }) / Double(recognizedObservations.count)

                let result = OCRResult(
                    fullText: fullText,
                    confidence: averageConfidence,
                    observations: recognizedObservations
                )

                continuation.resume(returning: result)
            }

            // Configure for receipt-optimized recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Receipt Parsing

    func parseReceiptData(from text: String) -> ParsedReceiptData {
        var data = ParsedReceiptData()
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Extract merchant name (typically first line or prominent text)
        data.merchantName = extractMerchantName(from: lines)

        // Extract total amount
        data.amount = extractTotalAmount(from: text)

        // Extract date
        data.date = extractDate(from: text)

        // Extract line items
        data.items = extractLineItems(from: lines)

        // Calculate overall confidence based on what was found
        var confidenceScore = 0.0
        if data.merchantName != nil { confidenceScore += 0.3 }
        if data.amount != nil { confidenceScore += 0.4 }
        if data.date != nil { confidenceScore += 0.2 }
        if !data.items.isEmpty { confidenceScore += 0.1 }
        data.confidence = confidenceScore

        return data
    }

    // MARK: - Private Extraction Methods

    private func extractMerchantName(from lines: [String]) -> String? {
        // Usually the first line contains the merchant name
        // Filter out common receipt headers
        let excludePatterns = ["receipt", "transaction", "invoice", "order", "welcome"]

        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lowercased = trimmed.lowercased()

            // Skip very short or numeric-only lines
            if trimmed.count < 3 { continue }
            if Double(trimmed.replacingOccurrences(of: " ", with: "")) != nil { continue }

            // Skip lines matching exclude patterns
            if excludePatterns.contains(where: { lowercased.contains($0) }) { continue }

            // Check if line looks like a business name
            if isLikelyBusinessName(trimmed) {
                return trimmed
            }
        }

        return lines.first?.trimmingCharacters(in: .whitespaces)
    }

    private func isLikelyBusinessName(_ text: String) -> Bool {
        // Heuristics for identifying business names
        let businessIndicators = ["inc", "llc", "corp", "store", "shop", "market", "restaurant", "cafe", "hotel", "pharmacy", "gas", "station"]

        let lowercased = text.lowercased()
        if businessIndicators.contains(where: { lowercased.contains($0) }) {
            return true
        }

        // Check for typical name patterns (capitalized words)
        let words = text.components(separatedBy: .whitespaces)
        let capitalizedWords = words.filter { word in
            guard let first = word.first else { return false }
            return first.isUppercase && word.count > 1
        }

        return capitalizedWords.count >= 1
    }

    private func extractTotalAmount(from text: String) -> Decimal? {
        // Common patterns for total amounts on receipts
        // Note: Using word boundary \b to avoid matching "subtotal" with "total"
        let patterns = [
            "\\btotal\\s*[:\\$]?\\s*\\$?([0-9]+\\.?[0-9]*)",
            "grand\\s*total\\s*[:\\$]?\\s*\\$?([0-9]+\\.?[0-9]*)",
            "amount\\s*due\\s*[:\\$]?\\s*\\$?([0-9]+\\.?[0-9]*)",
            "balance\\s*due\\s*[:\\$]?\\s*\\$?([0-9]+\\.?[0-9]*)"
        ]

        let lowercasedText = text.lowercased()

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowercasedText, options: [], range: NSRange(lowercasedText.startIndex..., in: lowercasedText)),
               let range = Range(match.range(at: 1), in: lowercasedText) {
                let amountString = String(lowercasedText[range]).replacingOccurrences(of: "$", with: "")
                if let amount = Decimal(string: amountString), amount > 0 {
                    return amount
                }
            }
        }

        // Fallback: find the largest dollar amount (likely the total)
        let amountRegex = try? NSRegularExpression(pattern: "\\$?([0-9]+\\.[0-9]{2})", options: [])
        let matches = amountRegex?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []

        var largestAmount: Decimal = 0
        for match in matches {
            if let range = Range(match.range(at: 1), in: text) {
                let amountString = String(text[range])
                if let amount = Decimal(string: amountString), amount > largestAmount {
                    largestAmount = amount
                }
            }
        }

        return largestAmount > 0 ? largestAmount : nil
    }

    private func extractDate(from text: String) -> Date? {
        // Common date patterns
        let datePatterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",       // MM/DD/YYYY or M/D/YY
            "\\d{1,2}-\\d{1,2}-\\d{2,4}",       // MM-DD-YYYY
            "\\d{4}-\\d{2}-\\d{2}",             // YYYY-MM-DD
            "[A-Za-z]{3}\\s+\\d{1,2},?\\s*\\d{4}" // Jan 15, 2024
        ]

        let dateFormatters: [DateFormatter] = [
            createFormatter("MM/dd/yyyy"),
            createFormatter("M/d/yyyy"),
            createFormatter("MM/dd/yy"),
            createFormatter("M/d/yy"),
            createFormatter("MM-dd-yyyy"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("MMM d, yyyy"),
            createFormatter("MMM dd, yyyy")
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])

                for formatter in dateFormatters {
                    if let date = formatter.date(from: dateString) {
                        // Validate the date is reasonable (not too far in past or future)
                        let yearComponent = Calendar.current.component(.year, from: date)
                        if yearComponent >= 2020 && yearComponent <= Calendar.current.component(.year, from: Date()) + 1 {
                            return date
                        }
                    }
                }
            }
        }

        return nil
    }

    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }

    private func extractLineItems(from lines: [String]) -> [String] {
        // Extract lines that look like item entries (have price patterns)
        let itemPattern = try? NSRegularExpression(pattern: "\\$?\\d+\\.\\d{2}$", options: [])

        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if line ends with a price
            if let regex = itemPattern,
               regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {

                // Exclude total/subtotal lines
                let lowercased = trimmed.lowercased()
                if lowercased.contains("total") || lowercased.contains("tax") || lowercased.contains("subtotal") {
                    return nil
                }

                return trimmed
            }

            return nil
        }
    }
}

// MARK: - OCR Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image. Please try again with a clearer photo."
        case .noTextFound:
            return "No text was detected in the image. Please ensure the receipt is clearly visible."
        case .recognitionFailed(let message):
            return "Text recognition failed: \(message)"
        case .parsingFailed:
            return "Unable to parse receipt data from the extracted text."
        }
    }
}
