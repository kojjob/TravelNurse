//
//  ExpenseCategorizationService.swift
//  TravelNurse
//
//  On-device ML service for smart expense categorization
//

import Foundation
import NaturalLanguage

/// Service for intelligently categorizing expenses using NLP
final class ExpenseCategorizationService: ExpenseCategorizationAI {

    // MARK: - Category Keywords

    /// Keywords and patterns for each expense category
    private let categoryKeywords: [ExpenseCategory: CategoryMatcher] = [
        .meals: CategoryMatcher(
            keywords: ["restaurant", "food", "lunch", "dinner", "breakfast", "coffee", "cafe", "diner",
                      "pizza", "burger", "sushi", "chinese", "mexican", "thai", "indian", "subway",
                      "chipotle", "mcdonald", "starbucks", "dunkin", "panera", "chick-fil-a",
                      "wendy", "taco bell", "grubhub", "doordash", "ubereats", "meal", "eat"],
            patterns: ["^(breakfast|lunch|dinner) at", "food delivery", "takeout"],
            isDeductible: true,
            deductionReason: "Business meals while on assignment (50% deductible)"
        ),

        .gasoline: CategoryMatcher(
            keywords: ["uber", "lyft", "taxi", "gas", "fuel", "parking", "toll", "transit",
                      "bus", "train", "metro", "subway", "airport", "shuttle", "rental car",
                      "hertz", "enterprise", "avis", "budget", "national", "shell", "exxon",
                      "chevron", "bp", "speedway", "wawa", "7-eleven", "parking garage"],
            patterns: ["gas station", "fuel stop", "parking fee", "toll road"],
            isDeductible: true,
            deductionReason: "Work-related transportation expenses"
        ),

        .rent: CategoryMatcher(
            keywords: ["hotel", "motel", "airbnb", "vrbo", "marriott", "hilton", "hyatt",
                      "holiday inn", "hampton", "residence inn", "extended stay", "rent",
                      "apartment", "housing", "lodging", "accommodation", "suite"],
            patterns: ["weekly rent", "monthly rent", "housing deposit", "accommodation"],
            isDeductible: true,
            deductionReason: "Temporary lodging while on assignment"
        ),

        .uniformsScrubs: CategoryMatcher(
            keywords: ["scrubs", "stethoscope", "medical", "nursing", "supplies", "uniform",
                      "shoes", "clogs", "compression", "badge", "lanyard", "pen light",
                      "bandage scissors", "nursing bag", "figs", "cherokee", "dickies",
                      "dansko", "allheart", "nursemates", "littmann"],
            patterns: ["medical supply", "nursing equipment", "work uniform"],
            isDeductible: true,
            deductionReason: "Required nursing supplies and uniforms"
        ),

        .continuingEducation: CategoryMatcher(
            keywords: ["ceu", "continuing education", "certification", "license", "exam",
                      "nclex", "acls", "bls", "pals", "cpr", "training", "course", "class",
                      "seminar", "conference", "workshop", "textbook", "study guide",
                      "subscription", "uptodate", "medscape", "nursing journal"],
            patterns: ["license renewal", "certification course", "continuing ed"],
            isDeductible: true,
            deductionReason: "Professional development and license maintenance"
        ),

        .utilities: CategoryMatcher(
            keywords: ["phone", "internet", "wifi", "mobile", "cellular", "verizon", "att",
                      "t-mobile", "sprint", "comcast", "spectrum", "cox", "electric",
                      "electricity", "water", "utility", "utilities", "bill"],
            patterns: ["phone bill", "internet bill", "utility payment"],
            isDeductible: true,
            deductionReason: "Work-related communication expenses (prorated)"
        ),

        .airfare: CategoryMatcher(
            keywords: ["flight", "airline", "airplane", "airport", "baggage", "luggage",
                      "southwest", "delta", "united", "american airlines", "jetblue",
                      "spirit", "frontier", "moving", "relocation", "pod", "uhaul",
                      "penske", "storage", "moving truck"],
            patterns: ["flight to", "travel to assignment", "relocation expense"],
            isDeductible: true,
            deductionReason: "Travel between tax home and assignment"
        ),

        .liability: CategoryMatcher(
            keywords: ["insurance", "malpractice", "liability", "health insurance",
                      "professional insurance", "nso", "proliability", "hpso",
                      "coverage", "premium"],
            patterns: ["insurance premium", "malpractice coverage"],
            isDeductible: true,
            deductionReason: "Professional liability insurance"
        ),

        .licensure: CategoryMatcher(
            keywords: ["license fee", "renewal fee", "application fee", "background check",
                      "fingerprint", "drug test", "physical", "credential", "verification",
                      "nursys", "state board", "agency fee", "subscription fee"],
            patterns: ["license application", "background screening", "credential verification"],
            isDeductible: true,
            deductionReason: "Professional licensing and credentialing fees"
        ),

        .other: CategoryMatcher(
            keywords: [],
            patterns: [],
            isDeductible: false,
            deductionReason: nil
        )
    ]

    // MARK: - NLP Components

    private let embedder: NLEmbedding?

    init() {
        embedder = NLEmbedding.wordEmbedding(for: .english)
    }

    // MARK: - ExpenseCategorizationAI

    func categorizeExpense(description: String, merchant: String?, amount: Decimal?) async throws -> ExpenseCategoryPrediction {
        let combinedText = [description, merchant].compactMap { $0 }.joined(separator: " ").lowercased()

        // Score each category
        var categoryScores: [(ExpenseCategory, Double)] = []

        for (category, matcher) in categoryKeywords {
            let score = calculateCategoryScore(text: combinedText, matcher: matcher)
            if score > 0 {
                categoryScores.append((category, score))
            }
        }

        // Sort by score
        categoryScores.sort { $0.1 > $1.1 }

        // Get best match
        if let bestMatch = categoryScores.first {
            let matcher = categoryKeywords[bestMatch.0]!
            let alternativeCategories = categoryScores.dropFirst().prefix(2).map { $0.0 }

            return ExpenseCategoryPrediction(
                category: bestMatch.0,
                confidence: min(bestMatch.1, 1.0),
                alternativeCategories: Array(alternativeCategories),
                isDeductible: matcher.isDeductible,
                deductionReason: matcher.deductionReason
            )
        }

        // Default to other
        return ExpenseCategoryPrediction(
            category: .other,
            confidence: 0.3,
            alternativeCategories: [],
            isDeductible: false,
            deductionReason: nil
        )
    }

    func categorizeExpenses(_ expenses: [ExpenseInput]) async throws -> [ExpenseCategoryPrediction] {
        var predictions: [ExpenseCategoryPrediction] = []

        for expense in expenses {
            let prediction = try await categorizeExpense(
                description: expense.description,
                merchant: expense.merchant,
                amount: expense.amount
            )
            predictions.append(ExpenseCategoryPrediction(
                id: expense.id,
                category: prediction.category,
                confidence: prediction.confidence,
                alternativeCategories: prediction.alternativeCategories,
                isDeductible: prediction.isDeductible,
                deductionReason: prediction.deductionReason
            ))
        }

        return predictions
    }

    // MARK: - Private Methods

    private func calculateCategoryScore(text: String, matcher: CategoryMatcher) -> Double {
        var score = 0.0

        // Keyword matching
        for keyword in matcher.keywords {
            if text.contains(keyword) {
                // Exact match gets higher score
                score += 0.3

                // Bonus for longer keywords (more specific)
                if keyword.count > 6 {
                    score += 0.1
                }
            }
        }

        // Pattern matching
        for pattern in matcher.patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil {
                score += 0.4
            }
        }

        // Use word embeddings for semantic similarity if available
        if let embedder = embedder {
            for keyword in matcher.keywords.prefix(5) {
                let words = text.components(separatedBy: .whitespaces)
                for word in words where word.count > 2 {
                    let distance = embedder.distance(between: word, and: keyword)
                    // Convert distance to similarity (lower distance = higher similarity)
                    // NLDistance returns NaN for unknown words, so check for valid distance
                    if !distance.isNaN && distance < 0.5 {
                        score += (0.5 - distance) * 0.2
                    }
                }
            }
        }

        return score
    }
}

// MARK: - Category Matcher

private struct CategoryMatcher {
    let keywords: [String]
    let patterns: [String]
    let isDeductible: Bool
    let deductionReason: String?
}

