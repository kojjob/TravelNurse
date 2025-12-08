//
//  AIServiceProtocol.swift
//  TravelNurse
//
//  Protocol definitions for AI services
//

import Foundation

// MARK: - AI Service Protocols

/// Main AI service protocol combining all AI capabilities
protocol AIServiceProtocol: ExpenseCategorizationAI, NaturalLanguageParserAI, TaxAssistantAI {}

/// AI for categorizing expenses
protocol ExpenseCategorizationAI {
    /// Categorize an expense based on description and merchant
    func categorizeExpense(description: String, merchant: String?, amount: Decimal?) async throws -> ExpenseCategoryPrediction

    /// Batch categorize multiple expenses
    func categorizeExpenses(_ expenses: [ExpenseInput]) async throws -> [ExpenseCategoryPrediction]
}

/// AI for parsing natural language input
protocol NaturalLanguageParserAI {
    /// Parse natural language into structured expense data
    func parseExpenseFromText(_ text: String) async throws -> ParsedExpenseIntent

    /// Parse natural language into mileage data
    func parseMileageFromText(_ text: String) async throws -> ParsedMileageIntent
}

/// AI for tax-related assistance
protocol TaxAssistantAI {
    /// Send a message to the tax assistant and get a response
    func sendMessage(_ message: String, context: TaxAssistantContext) async throws -> TaxAssistantResponse

    /// Get tax tips based on user's situation
    func getTaxTips(for context: TaxAssistantContext) async throws -> [TaxTip]
}

// MARK: - Data Models

/// Input for expense categorization
struct ExpenseInput: Identifiable {
    let id: UUID
    let description: String
    let merchant: String?
    let amount: Decimal?
    let date: Date?
}

/// Prediction result for expense category
struct ExpenseCategoryPrediction: Identifiable {
    let id: UUID
    let category: ExpenseCategory
    let confidence: Double
    let alternativeCategories: [ExpenseCategory]
    let isDeductible: Bool
    let deductionReason: String?

    init(
        id: UUID = UUID(),
        category: ExpenseCategory,
        confidence: Double,
        alternativeCategories: [ExpenseCategory] = [],
        isDeductible: Bool = false,
        deductionReason: String? = nil
    ) {
        self.id = id
        self.category = category
        self.confidence = confidence
        self.alternativeCategories = alternativeCategories
        self.isDeductible = isDeductible
        self.deductionReason = deductionReason
    }
}

/// Parsed expense intent from natural language
struct ParsedExpenseIntent {
    let amount: Decimal?
    let description: String?
    let merchant: String?
    let category: ExpenseCategory?
    let date: Date?
    let confidence: Double
    let rawText: String

    var isComplete: Bool {
        amount != nil && (description != nil || merchant != nil)
    }
}

/// Parsed mileage intent from natural language
struct ParsedMileageIntent {
    let miles: Double?
    let startLocation: String?
    let endLocation: String?
    let purpose: String?
    let date: Date?
    let confidence: Double
    let rawText: String

    var isComplete: Bool {
        miles != nil || (startLocation != nil && endLocation != nil)
    }
}

/// Context for tax assistant conversations
struct TaxAssistantContext {
    let taxYear: Int
    let taxHomeState: USState?
    let hasMultipleStates: Bool
    let ytdIncome: Decimal
    let ytdDeductions: Decimal
    let currentAssignment: AssignmentSummary?
    let conversationHistory: [ChatMessage]

    struct AssignmentSummary {
        let facilityName: String
        let state: USState
        let weeklyGross: Decimal
        let weeklyStipends: Decimal
        let weeksRemaining: Int
    }

    init(
        taxYear: Int = Calendar.current.component(.year, from: Date()),
        taxHomeState: USState? = nil,
        hasMultipleStates: Bool = false,
        ytdIncome: Decimal = 0,
        ytdDeductions: Decimal = 0,
        currentAssignment: AssignmentSummary? = nil,
        conversationHistory: [ChatMessage] = []
    ) {
        self.taxYear = taxYear
        self.taxHomeState = taxHomeState
        self.hasMultipleStates = hasMultipleStates
        self.ytdIncome = ytdIncome
        self.ytdDeductions = ytdDeductions
        self.currentAssignment = currentAssignment
        self.conversationHistory = conversationHistory
    }
}

/// Chat message for conversation history
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// Response from tax assistant
struct TaxAssistantResponse {
    let message: String
    let suggestions: [String]
    let relatedTopics: [String]
    let disclaimer: String?
    let confidence: Double

    init(
        message: String,
        suggestions: [String] = [],
        relatedTopics: [String] = [],
        disclaimer: String? = nil,
        confidence: Double = 1.0
    ) {
        self.message = message
        self.suggestions = suggestions
        self.relatedTopics = relatedTopics
        self.disclaimer = disclaimer
        self.confidence = confidence
    }
}

/// Tax tip suggestion
struct TaxTip: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: TipCategory
    let priority: Priority
    let potentialSavings: Decimal?

    enum TipCategory: String {
        case deduction = "Deduction"
        case compliance = "Compliance"
        case planning = "Planning"
        case warning = "Warning"
    }

    enum Priority: Int, Comparable {
        case low = 1
        case medium = 2
        case high = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TipCategory,
        priority: Priority,
        potentialSavings: Decimal? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.potentialSavings = potentialSavings
    }
}

// MARK: - AI Errors

enum AIServiceError: LocalizedError {
    case networkError(String)
    case apiKeyMissing
    case rateLimitExceeded
    case invalidResponse
    case parsingFailed(String)
    case contextTooLong
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiKeyMissing:
            return "API key is not configured. Please add your API key in Settings."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment and try again."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .parsingFailed(let message):
            return "Failed to parse response: \(message)"
        case .contextTooLong:
            return "The conversation is too long. Please start a new conversation."
        case .serviceUnavailable:
            return "AI service is temporarily unavailable. Please try again later."
        }
    }
}
