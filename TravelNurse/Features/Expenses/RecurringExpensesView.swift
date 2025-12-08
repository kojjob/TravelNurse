//
//  RecurringExpensesView.swift
//  TravelNurse
//
//  View for managing recurring expenses (rent, phone, subscriptions, etc.)
//

import SwiftUI
import SwiftData

/// View for managing recurring expenses
struct RecurringExpensesView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RecurringExpensesViewModel

    @State private var showingAddSheet = false
    @State private var selectedExpense: RecurringExpense?

    init() {
        _viewModel = State(initialValue: RecurringExpensesViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                // Summary Card
                if !viewModel.recurringExpenses.isEmpty {
                    Section {
                        summaryCard
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                // Active Recurring Expenses
                Section {
                    if viewModel.activeExpenses.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.activeExpenses) { expense in
                            RecurringExpenseRow(
                                expense: expense,
                                onTap: { selectedExpense = expense },
                                onPause: { viewModel.pause(expense) }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.activeExpenses[index])
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Active")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }

                // Paused Expenses
                if !viewModel.pausedExpenses.isEmpty {
                    Section {
                        ForEach(viewModel.pausedExpenses) { expense in
                            RecurringExpenseRow(
                                expense: expense,
                                onTap: { selectedExpense = expense },
                                onResume: { viewModel.resume(expense) }
                            )
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.delete(viewModel.pausedExpenses[index])
                            }
                        }
                    } header: {
                        Text("Paused")
                    }
                }

                // Quick Add Suggestions
                Section {
                    quickAddSection
                } header: {
                    Text("Quick Add")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Recurring Expenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .refreshable {
                await viewModel.loadData(modelContext: modelContext)
            }
            .task {
                await viewModel.loadData(modelContext: modelContext)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRecurringExpenseSheet { name, category, amount, frequency, merchant in
                    viewModel.create(
                        name: name,
                        category: category,
                        amount: amount,
                        frequency: frequency,
                        merchantName: merchant
                    )
                }
            }
            .sheet(item: $selectedExpense) { expense in
                EditRecurringExpenseSheet(expense: expense) { updated in
                    viewModel.update(updated)
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "7C3AED"), // Violet 600
                    Color(hex: "6D28D9"), // Violet 700
                    Color(hex: "5B21B6")  // Violet 800
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .offset(x: geo.size.width - 50, y: -20)
                    .blur(radius: 15)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MONTHLY TOTAL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1)

                        Text(viewModel.summary.formattedMonthlyTotal)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(viewModel.summary.activeCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("active")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ANNUAL")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                        Text(viewModel.summary.formattedAnnualTotal)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if viewModel.dueCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("\(viewModel.dueCount) due")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.9))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color(hex: "5B21B6").opacity(0.3), radius: 12, x: 0, y: 8)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 40))
                .foregroundColor(TNColors.textSecondary.opacity(0.5))

            Text("No Recurring Expenses")
                .font(.headline)
                .foregroundColor(TNColors.textPrimary)

            Text("Add regular expenses like rent, phone bills, or subscriptions to track automatically.")
                .font(.caption)
                .foregroundColor(TNColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                Label("Add Recurring Expense", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Quick Add Section

    private var quickAddSection: some View {
        Group {
            QuickAddButton(
                title: "Housing/Rent",
                icon: "building.2.fill",
                color: TNColors.secondary
            ) {
                viewModel.quickAdd(template: .housing)
                showingAddSheet = true
            }

            QuickAddButton(
                title: "Cell Phone",
                icon: "phone.fill",
                color: TNColors.indigo
            ) {
                viewModel.quickAdd(template: .cellPhone)
                showingAddSheet = true
            }

            QuickAddButton(
                title: "Internet",
                icon: "wifi",
                color: TNColors.primary
            ) {
                viewModel.quickAdd(template: .internet)
                showingAddSheet = true
            }

            QuickAddButton(
                title: "Insurance",
                icon: "shield.fill",
                color: TNColors.accent
            ) {
                viewModel.quickAdd(template: .insurance)
                showingAddSheet = true
            }
        }
    }
}

// MARK: - Recurring Expense Row

struct RecurringExpenseRow: View {
    let expense: RecurringExpense
    let onTap: () -> Void
    var onPause: (() -> Void)? = nil
    var onResume: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(expense.category.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: expense.category.iconName)
                        .font(.title3)
                        .foregroundColor(expense.category.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(expense.isActive ? TNColors.textPrimary : TNColors.textSecondary)

                    HStack(spacing: 8) {
                        Text(expense.frequency.displayName)
                            .font(.caption)
                            .foregroundColor(TNColors.textSecondary)

                        if let merchant = expense.merchantName, !merchant.isEmpty {
                            Text("•")
                                .foregroundColor(TNColors.textSecondary)
                            Text(merchant)
                                .font(.caption)
                                .foregroundColor(TNColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Amount and status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(expense.formattedAmount)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(TNColors.textPrimary)

                    if !expense.isActive {
                        Text("Paused")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(TNColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(TNColors.textSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    } else if expense.isDue {
                        Text("Due")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(TNColors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(TNColors.warning.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                // Delete handled by parent
            } label: {
                Label("Delete", systemImage: "trash")
            }

            if expense.isActive, let pause = onPause {
                Button {
                    pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .tint(.orange)
            }

            if !expense.isActive, let resume = onResume {
                Button {
                    resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .tint(.green)
            }
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(title)
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                Image(systemName: "plus.circle")
                    .foregroundColor(TNColors.textSecondary)
            }
        }
    }
}

// MARK: - Add Recurring Expense Sheet

struct AddRecurringExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ExpenseCategory = .rent
    @State private var amount = ""
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var merchantName = ""

    let onSave: (String, ExpenseCategory, Decimal, RecurrenceFrequency, String?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }

                Section("Optional") {
                    TextField("Merchant/Vendor", text: $merchantName)
                }
            }
            .navigationTitle("Add Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let decimalAmount = Decimal(string: amount) ?? 0
                        onSave(name, category, decimalAmount, frequency, merchantName.isEmpty ? nil : merchantName)
                        dismiss()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Recurring Expense Sheet

struct EditRecurringExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss

    let expense: RecurringExpense
    let onSave: (RecurringExpense) -> Void

    @State private var name: String
    @State private var category: ExpenseCategory
    @State private var amount: String
    @State private var frequency: RecurrenceFrequency
    @State private var merchantName: String

    init(expense: RecurringExpense, onSave: @escaping (RecurringExpense) -> Void) {
        self.expense = expense
        self.onSave = onSave
        _name = State(initialValue: expense.name)
        _category = State(initialValue: expense.category)
        _amount = State(initialValue: "\((expense.amount as NSDecimalNumber).intValue)")
        _frequency = State(initialValue: expense.frequency)
        _merchantName = State(initialValue: expense.merchantName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                }

                Section("Optional") {
                    TextField("Merchant/Vendor", text: $merchantName)
                }

                Section {
                    LabeledContent("Generated", value: "\(expense.generatedCount) expenses")
                    LabeledContent("Total", value: expense.formattedAmount)
                }
            }
            .navigationTitle("Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        expense.name = name
                        expense.category = category
                        expense.amount = Decimal(string: amount) ?? expense.amount
                        expense.frequency = frequency
                        expense.merchantName = merchantName.isEmpty ? nil : merchantName
                        onSave(expense)
                        dismiss()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RecurringExpensesView()
        .modelContainer(for: [
            RecurringExpense.self,
            Expense.self
        ], inMemory: true)
}
