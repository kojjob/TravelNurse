//
//  TaxAssistantViewModel.swift
//  TravelNurse
//
//  ViewModel for AI Tax Assistant
//

import Foundation
import SwiftUI

/// ViewModel managing Tax Assistant chat state
@MainActor
@Observable
final class TaxAssistantViewModel {

    // MARK: - State

    /// Chat messages
    var messages: [ChatMessage] = []

    /// Current input text
    var inputText = ""

    /// Is AI typing/thinking
    private(set) var isTyping = false

    /// Suggested follow-up questions
    var suggestions: [String] = [
        "What is a tax home?",
        "How do stipends work?",
        "What can I deduct?"
    ]

    /// Tax tips
    private(set) var taxTips: [TaxTip] = []

    /// Show tips sheet
    var showTips = false

    /// Error message
    private(set) var errorMessage: String?
    var showError = false

    /// Context for AI
    private var context: TaxAssistantContext

    // MARK: - Dependencies

    private let taxAssistant: TaxAssistantService

    // MARK: - Computed Properties

    /// Can send message
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTyping
    }

    // MARK: - Initialization

    init(taxAssistant: TaxAssistantService = TaxAssistantService()) {
        self.taxAssistant = taxAssistant
        self.context = TaxAssistantContext()
    }

    // MARK: - Actions

    /// Load context from app data
    func loadContext() async {
        // Load user's context from stored data
        // This would typically load from ServiceContainer
        context = TaxAssistantContext(
            taxYear: Calendar.current.component(.year, from: Date()),
            taxHomeState: .texas, // Would load from UserDefaults/SwiftData
            hasMultipleStates: false,
            ytdIncome: 0,
            ytdDeductions: 0,
            conversationHistory: messages
        )
    }

    /// Load tax tips
    func loadTaxTips() async {
        do {
            taxTips = try await taxAssistant.getTaxTips(for: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Send current message from input
    func sendCurrentMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        sendMessage(text)
    }

    /// Send a message
    func sendMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        // Update context
        context = TaxAssistantContext(
            taxYear: context.taxYear,
            taxHomeState: context.taxHomeState,
            hasMultipleStates: context.hasMultipleStates,
            ytdIncome: context.ytdIncome,
            ytdDeductions: context.ytdDeductions,
            currentAssignment: context.currentAssignment,
            conversationHistory: messages
        )

        // Clear suggestions while waiting
        suggestions = []

        // Get AI response
        Task {
            await getResponse(for: text)
        }
    }

    /// Clear conversation
    func clearConversation() {
        messages.removeAll()
        suggestions = [
            "What is a tax home?",
            "How do stipends work?",
            "What can I deduct?"
        ]
    }

    // MARK: - Private Methods

    private func getResponse(for message: String) async {
        isTyping = true

        // Simulate typing delay for natural feel
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        do {
            let response = try await taxAssistant.sendMessage(message, context: context)

            // Create assistant message
            var fullMessage = response.message

            // Add disclaimer if present
            if let disclaimer = response.disclaimer {
                fullMessage += "\n\n_\(disclaimer)_"
            }

            let assistantMessage = ChatMessage(role: .assistant, content: fullMessage)
            messages.append(assistantMessage)

            // Update suggestions
            suggestions = response.suggestions

        } catch {
            let errorMessage = ChatMessage(
                role: .assistant,
                content: "I'm sorry, I encountered an error. Please try again."
            )
            messages.append(errorMessage)
            suggestions = ["What is a tax home?", "What can I deduct?"]
        }

        isTyping = false
    }
}
