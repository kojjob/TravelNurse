//
//  QuickAddExpenseView.swift
//  TravelNurse
//
//  Natural language expense entry with AI parsing
//

import SwiftUI
import UIKit

/// Quick add expense using natural language
struct QuickAddExpenseView: View {

    @State private var viewModel = QuickAddExpenseViewModel()
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    let onSave: ((ParsedExpenseIntent) -> Void)?

    init(onSave: ((ParsedExpenseIntent) -> Void)? = nil) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Input section
                    inputSection

                    // Parsed preview
                    if viewModel.parsedExpense != nil {
                        parsedPreviewSection
                    }

                    Spacer()

                    // Example prompts
                    if viewModel.inputText.isEmpty {
                        examplesSection
                    }
                }
                .background(Color(hex: "F8FAFC"))

                // Success overlay
                if showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveExpense()
                    }
                    .disabled(!viewModel.canSave || showSuccess)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(TNColors.success)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(showSuccess ? 1.0 : 0.5)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSuccess)

                Text("Expense Added!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
        .transition(.opacity)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 16) {
            // AI icon
            ZStack {
                Circle()
                    .fill(TNColors.primary.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20))
                    .foregroundColor(TNColors.primary)
            }

            Text("Describe your expense")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(TNColors.textSecondary)

            // Text input
            TextField("e.g., $25 lunch at Chipotle", text: $viewModel.inputText, axis: .vertical)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .lineLimit(1...3)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
                .focused($isInputFocused)
                .onChange(of: viewModel.inputText) { _, newValue in
                    viewModel.parseInput(newValue)
                }
        }
        .padding()
        .padding(.top, 20)
    }

    // MARK: - Parsed Preview

    private var parsedPreviewSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("I understood:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TNColors.textSecondary)

                Spacer()

                // Confidence indicator
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(index < Int(viewModel.confidence * 5) ? TNColors.success : TNColors.textTertiary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            // Preview card
            VStack(spacing: 12) {
                // Amount
                if let amount = viewModel.parsedExpense?.amount {
                    HStack {
                        Label("Amount", systemImage: "dollarsign.circle")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.textSecondary)
                        Spacer()
                        Text(TNFormatters.currency(amount))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(TNColors.success)
                    }
                }

                Divider()

                // Merchant
                if let merchant = viewModel.parsedExpense?.merchant {
                    HStack {
                        Label("Merchant", systemImage: "building.2")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.textSecondary)
                        Spacer()
                        Text(merchant)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(TNColors.textPrimary)
                    }
                }

                // Description
                if let description = viewModel.parsedExpense?.description {
                    HStack {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.textSecondary)
                        Spacer()
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundColor(TNColors.textPrimary)
                    }
                }

                Divider()

                // Category
                if let category = viewModel.parsedExpense?.category {
                    HStack {
                        Label("Category", systemImage: "tag")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.textSecondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .foregroundColor(category.color)
                            Text(category.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(TNColors.textPrimary)
                        }
                    }
                }

                // Date
                if let date = viewModel.parsedExpense?.date {
                    HStack {
                        Label("Date", systemImage: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(TNColors.textSecondary)
                        Spacer()
                        Text(TNFormatters.date(date))
                            .font(.system(size: 15))
                            .foregroundColor(TNColors.textPrimary)
                    }
                }

                // Deductible badge
                if let category = viewModel.parsedExpense?.category, viewModel.isDeductible {
                    HStack {
                        Spacer()
                        Label("Tax Deductible", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(TNColors.success)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(TNColors.success.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        }
        .padding(.horizontal)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: viewModel.parsedExpense?.amount)
    }

    // MARK: - Examples

    private var examplesSection: some View {
        VStack(spacing: 16) {
            Text("Try saying:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TNColors.textTertiary)

            VStack(spacing: 8) {
                ExampleButton(text: "$45 for lunch at Panera") {
                    viewModel.inputText = "$45 for lunch at Panera"
                    viewModel.parseInput(viewModel.inputText)
                }

                ExampleButton(text: "Spent $120 on new scrubs") {
                    viewModel.inputText = "Spent $120 on new scrubs"
                    viewModel.parseInput(viewModel.inputText)
                }

                ExampleButton(text: "Gas $55 at Shell yesterday") {
                    viewModel.inputText = "Gas $55 at Shell yesterday"
                    viewModel.parseInput(viewModel.inputText)
                }

                ExampleButton(text: "Uber to hospital $18.50") {
                    viewModel.inputText = "Uber to hospital $18.50"
                    viewModel.parseInput(viewModel.inputText)
                }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func saveExpense() {
        guard let parsed = viewModel.parsedExpense else { return }

        // Trigger haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Call the save callback
        onSave?(parsed)

        // Show success overlay with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showSuccess = true
        }

        // Dismiss after showing success feedback
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            dismiss()
        }
    }
}

// MARK: - Example Button

struct ExampleButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "text.bubble")
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.primary.opacity(0.6))

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.textSecondary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(TNColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class QuickAddExpenseViewModel {

    var inputText = ""
    private(set) var parsedExpense: ParsedExpenseIntent?
    private(set) var confidence: Double = 0
    private(set) var isDeductible = false

    @ObservationIgnored private let categorizationService: ExpenseCategorizationService
    @ObservationIgnored private let parser: NaturalLanguageParserService

    init() {
        let service = ExpenseCategorizationService()
        let parserInstance = NaturalLanguageParserService(categorizationService: service)
        
        self.categorizationService = service
        self.parser = parserInstance
    }

    private var parseTask: Task<Void, Never>?

    var canSave: Bool {
        parsedExpense?.isComplete ?? false
    }

    func parseInput(_ text: String) {
        // Cancel previous parse task
        parseTask?.cancel()

        guard !text.isEmpty else {
            parsedExpense = nil
            confidence = 0
            isDeductible = false
            return
        }

        // Debounce parsing
        parseTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            guard !Task.isCancelled else { return }

            do {
                let result = try await parser.parseExpenseFromText(text)
                parsedExpense = result
                confidence = result.confidence

                // Check if deductible based on category
                if let category = result.category {
                    let prediction = try await categorizationService.categorizeExpense(
                        description: result.description ?? text,
                        merchant: result.merchant,
                        amount: result.amount
                    )
                    isDeductible = prediction.isDeductible
                } else {
                    isDeductible = false
                }
            } catch {
                parsedExpense = nil
                confidence = 0
                isDeductible = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuickAddExpenseView()
}
