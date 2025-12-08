//
//  NaturalLanguageParserService.swift
//  TravelNurse
//
//  Natural language parsing for expense and mileage entry
//

import Foundation
import NaturalLanguage

/// Service for parsing natural language into structured data
final class NaturalLanguageParserService: NaturalLanguageParserAI {

    // MARK: - Components

    private let tagger: NLTagger
    private let categorizationService: ExpenseCategorizationService

    init(categorizationService: ExpenseCategorizationService = ExpenseCategorizationService()) {
        self.tagger = NLTagger(tagSchemes: [.tokenType, .lexicalClass, .nameType, .lemma])
        self.categorizationService = categorizationService
    }

    // MARK: - Expense Parsing

    func parseExpenseFromText(_ text: String) async throws -> ParsedExpenseIntent {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Extract components
        let amount = extractAmount(from: text)
        let merchant = extractMerchant(from: text)
        let date = extractDate(from: text)
        let description = extractDescription(from: text, excludingMerchant: merchant)

        // Determine category based on extracted info
        let categoryPrediction = try await categorizationService.categorizeExpense(
            description: description ?? normalizedText,
            merchant: merchant,
            amount: amount
        )

        // Calculate confidence based on what was extracted
        var confidence = 0.0
        if amount != nil { confidence += 0.4 }
        if merchant != nil || description != nil { confidence += 0.3 }
        if date != nil { confidence += 0.1 }
        confidence += categoryPrediction.confidence * 0.2

        return ParsedExpenseIntent(
            amount: amount,
            description: description,
            merchant: merchant,
            category: categoryPrediction.category,
            date: date,
            confidence: min(confidence, 1.0),
            rawText: text
        )
    }

    // MARK: - Mileage Parsing

    func parseMileageFromText(_ text: String) async throws -> ParsedMileageIntent {
        let normalizedText = text.lowercased()

        // Extract miles
        let miles = extractMiles(from: normalizedText)

        // Extract locations
        let (startLocation, endLocation) = extractLocations(from: text)

        // Extract purpose
        let purpose = extractTripPurpose(from: normalizedText)

        // Extract date
        let date = extractDate(from: text)

        // Calculate confidence
        var confidence = 0.0
        if miles != nil { confidence += 0.5 }
        if startLocation != nil || endLocation != nil { confidence += 0.3 }
        if purpose != nil { confidence += 0.1 }
        if date != nil { confidence += 0.1 }

        return ParsedMileageIntent(
            miles: miles,
            startLocation: startLocation,
            endLocation: endLocation,
            purpose: purpose,
            date: date,
            confidence: min(confidence, 1.0),
            rawText: text
        )
    }

    // MARK: - Amount Extraction

    private func extractAmount(from text: String) -> Decimal? {
        // Patterns for dollar amounts
        let patterns = [
            "\\$([0-9]+(?:\\.[0-9]{1,2})?)",           // $45.67
            "\\$([0-9]+)",                             // $45
            "([0-9]+(?:\\.[0-9]{1,2})?)\\s*dollars?",  // 45 dollars, 45.67 dollars
            "([0-9]+(?:\\.[0-9]{1,2})?)\\s*bucks?",    // 45 bucks
            "spent\\s*\\$?([0-9]+(?:\\.[0-9]{1,2})?)", // spent $45
            "paid\\s*\\$?([0-9]+(?:\\.[0-9]{1,2})?)",  // paid 45.67
            "cost\\s*\\$?([0-9]+(?:\\.[0-9]{1,2})?)",  // cost $45
            "for\\s*\\$?([0-9]+(?:\\.[0-9]{1,2})?)"    // for $45
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let amountString = String(text[range]).replacingOccurrences(of: "$", with: "")
                if let amount = Decimal(string: amountString), amount > 0 && amount < 100000 {
                    return amount
                }
            }
        }

        return nil
    }

    // MARK: - Merchant Extraction

    private func extractMerchant(from text: String) -> String? {
        // Common patterns for merchant mentions
        let patterns = [
            "(?:at|from|to)\\s+([A-Z][A-Za-z']+(?:\\s+[A-Z][A-Za-z']+)*)",  // at Starbucks
            "(?:at|from|to)\\s+([A-Za-z]+(?:'s)?)",                          // at McDonald's
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let merchant = String(text[range]).trimmingCharacters(in: .whitespaces)
                if merchant.count > 1 && !isCommonWord(merchant) {
                    return merchant
                }
            }
        }

        // Use NLP to find organization names
        tagger.string = text
        var foundMerchant: String?

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if tag == .organizationName {
                foundMerchant = String(text[range])
                return false
            }
            return true
        }

        return foundMerchant
    }

    // MARK: - Description Extraction

    private func extractDescription(from text: String, excludingMerchant merchant: String?) -> String? {
        var description = text

        // Remove amount patterns
        let amountPatterns = ["\\$[0-9]+(?:\\.[0-9]{1,2})?", "[0-9]+(?:\\.[0-9]{1,2})?\\s*(?:dollars?|bucks?)"]
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                description = regex.stringByReplacingMatches(in: description, options: [], range: NSRange(description.startIndex..., in: description), withTemplate: "")
            }
        }

        // Remove merchant if found
        if let merchant = merchant {
            description = description.replacingOccurrences(of: merchant, with: "", options: .caseInsensitive)
        }

        // Remove common filler words
        let fillerWords = ["add", "log", "spent", "paid", "for", "at", "on", "the", "a", "an"]
        var words = description.components(separatedBy: .whitespaces)
        words = words.filter { !fillerWords.contains($0.lowercased()) && !$0.isEmpty }

        let cleaned = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned.capitalized
    }

    // MARK: - Date Extraction

    private func extractDate(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let today = Date()

        // Handle relative dates
        if lowercased.contains("today") {
            return today
        }
        if lowercased.contains("yesterday") {
            return calendar.date(byAdding: .day, value: -1, to: today)
        }
        if lowercased.contains("last week") {
            return calendar.date(byAdding: .day, value: -7, to: today)
        }

        // Handle day names
        let dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        for (index, day) in dayNames.enumerated() {
            if lowercased.contains("last \(day)") {
                // Find last occurrence of this weekday
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
                components.weekday = index + 1
                if let date = calendar.date(from: components) {
                    return calendar.date(byAdding: .day, value: -7, to: date)
                }
            } else if lowercased.contains(day) {
                // Find most recent occurrence
                var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
                components.weekday = index + 1
                if let date = calendar.date(from: components), date <= today {
                    return date
                }
            }
        }

        // Try to parse explicit dates
        let datePatterns = [
            "\\d{1,2}/\\d{1,2}(?:/\\d{2,4})?",  // 12/25 or 12/25/24
            "\\d{1,2}-\\d{1,2}(?:-\\d{2,4})?"   // 12-25 or 12-25-24
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let dateString = String(text[range])
                if let date = parseExplicitDate(dateString) {
                    return date
                }
            }
        }

        return nil
    }

    private func parseExplicitDate(_ dateString: String) -> Date? {
        let formatters = [
            createFormatter("M/d/yyyy"),
            createFormatter("M/d/yy"),
            createFormatter("M/d"),
            createFormatter("M-d-yyyy"),
            createFormatter("M-d-yy"),
            createFormatter("M-d")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                // If no year was specified, use current year
                let calendar = Calendar.current
                if !dateString.contains("/20") && !dateString.contains("-20") {
                    var components = calendar.dateComponents([.month, .day], from: date)
                    components.year = calendar.component(.year, from: Date())
                    return calendar.date(from: components)
                }
                return date
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

    // MARK: - Mileage Extraction

    private func extractMiles(from text: String) -> Double? {
        let patterns = [
            "([0-9]+(?:\\.[0-9]+)?)\\s*(?:miles?|mi)",  // 23 miles, 23.5 mi
            "drove\\s+([0-9]+(?:\\.[0-9]+)?)",          // drove 23
            "logged?\\s+([0-9]+(?:\\.[0-9]+)?)"         // log 23
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                if let miles = Double(String(text[range])), miles > 0 && miles < 10000 {
                    return miles
                }
            }
        }

        return nil
    }

    private func extractLocations(from text: String) -> (start: String?, end: String?) {
        // Pattern: from X to Y
        if let regex = try? NSRegularExpression(pattern: "from\\s+(.+?)\\s+to\\s+(.+?)(?:\\s|$)", options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let startRange = Range(match.range(at: 1), in: text),
           let endRange = Range(match.range(at: 2), in: text) {
            return (String(text[startRange]), String(text[endRange]))
        }

        // Pattern: to X
        if let regex = try? NSRegularExpression(pattern: "(?:to|toward)\\s+(?:the\\s+)?(.+?)(?:\\s|$)", options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return (nil, String(text[range]))
        }

        return (nil, nil)
    }

    private func extractTripPurpose(from text: String) -> String? {
        let purposes = [
            "work": "Work",
            "hospital": "Hospital",
            "clinic": "Clinic",
            "patient": "Patient Visit",
            "training": "Training",
            "meeting": "Meeting",
            "orientation": "Orientation",
            "interview": "Interview"
        ]

        for (keyword, purpose) in purposes {
            if text.contains(keyword) {
                return purpose
            }
        }

        return nil
    }

    // MARK: - Helpers

    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = Set(["the", "a", "an", "for", "to", "at", "on", "in", "and", "or", "but", "with", "from"])
        return commonWords.contains(word.lowercased())
    }
}
