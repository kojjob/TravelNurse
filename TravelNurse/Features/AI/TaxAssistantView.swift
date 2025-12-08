//
//  TaxAssistantView.swift
//  TravelNurse
//
//  AI-powered tax assistant chat interface
//

import SwiftUI

/// AI Tax Assistant chat interface for travel nurses
struct TaxAssistantView: View {

    @State private var viewModel = TaxAssistantViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if viewModel.messages.isEmpty {
                                welcomeSection
                            }

                            // Messages
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            // Typing indicator
                            if viewModel.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { _, isTyping in
                        if isTyping {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // Suggestions
                if !viewModel.suggestions.isEmpty && viewModel.inputText.isEmpty {
                    suggestionsBar
                }

                // Input bar
                inputBar
            }
            .background(Color(hex: "F8FAFC"))
            .navigationTitle("Tax Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.clearConversation()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }

                        Button {
                            viewModel.showTips = true
                        } label: {
                            Label("Tax Tips", systemImage: "lightbulb")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(TNColors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showTips) {
                TaxTipsSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadContext()
            }
        }
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: 20) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [TNColors.primary, TNColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Tax Assistant")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(TNColors.textPrimary)

                Text("I can help with travel nurse tax questions.\nAsk me about tax home, stipends, deductions, and more!")
                    .font(.system(size: 15))
                    .foregroundColor(TNColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Quick questions
            VStack(spacing: 10) {
                Text("Try asking:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TNColors.textTertiary)

                VStack(spacing: 8) {
                    QuickQuestionButton(text: "What is a tax home?") {
                        viewModel.sendMessage("What is a tax home?")
                    }

                    QuickQuestionButton(text: "Are my stipends taxable?") {
                        viewModel.sendMessage("Are my stipends taxable?")
                    }

                    QuickQuestionButton(text: "What can I deduct?") {
                        viewModel.sendMessage("What expenses can I deduct?")
                    }
                }
            }
            .padding(.top, 8)

            // Disclaimer
            Text("This is general guidance only, not professional tax advice.")
                .font(.system(size: 11))
                .foregroundColor(TNColors.textTertiary)
                .padding(.top, 16)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Suggestions Bar

    private var suggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.sendMessage(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(TNColors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(TNColors.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask a tax question...", text: $viewModel.inputText, axis: .vertical)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "F1F5F9"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...4)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    viewModel.sendCurrentMessage()
                }

            Button {
                viewModel.sendCurrentMessage()
                isInputFocused = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.canSend ? TNColors.primary : TNColors.textTertiary)
            }
            .disabled(!viewModel.canSend)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: -2)
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(TNColors.primary.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(TNColors.primary)
                }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message content - safely parse markdown
                Text(Self.parseMarkdown(message.content))
                    .font(.system(size: 15))
                    .foregroundColor(message.role == .user ? .white : TNColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user ?
                            AnyShapeStyle(LinearGradient(
                                colors: [TNColors.primary, TNColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )) :
                            AnyShapeStyle(Color.white)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)

                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(TNColors.textTertiary)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    // MARK: - Static Helpers

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static func parseMarkdown(_ content: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: content,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(content)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotScales: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(TNColors.primary.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.primary)
            }

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(TNColors.textTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScales[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)

            Spacer()
        }
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for index in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.4)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15)
            ) {
                dotScales[index] = 1.3
            }
        }
    }
}

// MARK: - Quick Question Button

struct QuickQuestionButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "questionmark.bubble")
                    .font(.system(size: 14))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(TNColors.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: 280)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        }
    }
}

// MARK: - Tax Tips Sheet

struct TaxTipsSheet: View {
    @Bindable var viewModel: TaxAssistantViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.taxTips.isEmpty {
                    ContentUnavailableView(
                        "Loading Tips",
                        systemImage: "lightbulb",
                        description: Text("Getting personalized tips...")
                    )
                } else {
                    ForEach(viewModel.taxTips) { tip in
                        TaxTipRow(tip: tip)
                    }
                }
            }
            .navigationTitle("Tax Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.loadTaxTips()
            }
        }
    }
}

// MARK: - Tax Tip Row

struct TaxTipRow: View {
    let tip: TaxTip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)

                Text(tip.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                if let savings = tip.potentialSavings {
                    Text("~\(TNFormatters.currencyWhole(savings))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(TNColors.success)
                }
            }

            Text(tip.description)
                .font(.system(size: 14))
                .foregroundColor(TNColors.textSecondary)
                .lineLimit(3)

            HStack {
                Text(tip.category.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                priorityBadge
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch tip.category {
        case .deduction: return "dollarsign.circle"
        case .compliance: return "checkmark.shield"
        case .planning: return "calendar"
        case .warning: return "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch tip.category {
        case .deduction: return TNColors.success
        case .compliance: return TNColors.info
        case .planning: return TNColors.primary
        case .warning: return TNColors.warning
        }
    }

    private var categoryColor: Color {
        iconColor
    }

    private var priorityBadge: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < tip.priority.rawValue ? TNColors.warning : TNColors.textTertiary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TaxAssistantView()
}
