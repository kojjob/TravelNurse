//
//  AddExpenseSheet.swift
//  TravelNurse
//
//  Quick expense entry sheet accessible from Home screen
//

import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: ExpenseCategory = .meals
    @State private var amount: String = ""
    @State private var merchantName: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var isDeductible: Bool = true
    @State private var showingCategoryPicker = false
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // Amount Section
                Section {
                    HStack {
                        Text("$")
                            .font(.title)
                            .foregroundColor(TNColors.textSecondary)

                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(TNColors.textPrimary)
                    }
                    .padding(.vertical, TNSpacing.sm)
                } header: {
                    Text("Amount")
                }

                // Category Section
                Section {
                    Button {
                        showingCategoryPicker = true
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory.color.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Image(systemName: selectedCategory.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedCategory.color)
                            }

                            Text(selectedCategory.displayName)
                                .foregroundColor(TNColors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(TNColors.textTertiary)
                        }
                    }
                } header: {
                    Text("Category")
                }

                // Details Section
                Section {
                    TextField("Merchant name (optional)", text: $merchantName)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
                }

                // Tax Section
                Section {
                    Toggle("Tax Deductible", isOn: $isDeductible)
                } footer: {
                    Text("Deductible expenses reduce your taxable income")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textTertiary)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                SimpleCategoryPickerSheet(selectedCategory: $selectedCategory)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveExpense() {
        guard let amountDecimal = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        guard amountDecimal > 0 else {
            errorMessage = "Amount must be greater than zero"
            showError = true
            return
        }

        isSaving = true

        let expense = Expense(
            category: selectedCategory,
            amount: amountDecimal,
            date: date,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            notes: notes.isEmpty ? nil : notes,
            isDeductible: isDeductible
        )

        modelContext.insert(expense)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save expense: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }
}

// MARK: - Simple Category Picker Sheet

private struct SimpleCategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ExpenseCategory

    var body: some View {
        NavigationStack {
            List {
                ForEach(ExpenseGroup.allCases) { group in
                    Section(group.rawValue) {
                        ForEach(group.categories) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(category.color.opacity(0.1))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: category.iconName)
                                            .font(.system(size: 16))
                                            .foregroundColor(category.color)
                                    }

                                    Text(category.displayName)
                                        .foregroundColor(TNColors.textPrimary)

                                    Spacer()

                                    if category == selectedCategory {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(TNColors.primary)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddExpenseSheet()
        .modelContainer(for: Expense.self, inMemory: true)
}
