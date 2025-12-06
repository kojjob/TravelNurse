//
//  AddIncomeSheet.swift
//  TravelNurse
//
//  Quick income entry sheet accessible from Home screen
//

import SwiftUI
import SwiftData

struct AddIncomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedType: IncomeType = .bonus
    @State private var amount: String = ""
    @State private var source: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var isTaxable: Bool = true
    @State private var showingTypePicker = false
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
                            .foregroundColor(TNColors.primary)
                    }
                    .padding(.vertical, TNSpacing.sm)
                } header: {
                    Text("Amount")
                }

                // Income Type Section
                Section {
                    Button {
                        showingTypePicker = true
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(TNColors.primary.opacity(0.1))
                                    .frame(width: 36, height: 36)

                                Image(systemName: selectedType.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(TNColors.primary)
                            }

                            Text(selectedType.rawValue)
                                .foregroundColor(TNColors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(TNColors.textTertiary)
                        }
                    }
                } header: {
                    Text("Income Type")
                }

                // Details Section
                Section {
                    TextField("Source (e.g., Agency name)", text: $source)

                    DatePicker("Date Received", selection: $date, displayedComponents: .date)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Details")
                }

                // Tax Section
                Section {
                    Toggle("Taxable Income", isOn: $isTaxable)
                } footer: {
                    Text(taxabilityFooterText)
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textTertiary)
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingTypePicker) {
                IncomeTypePickerSheet(selectedType: $selectedType, isTaxable: $isTaxable)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: selectedType) { _, newValue in
                // Update taxable status based on type's default
                isTaxable = newValue.defaultTaxable
            }
        }
    }

    private var taxabilityFooterText: String {
        if isTaxable {
            return "Taxable income will be included in your reported earnings"
        } else {
            return "Non-taxable income (stipends, per diem) that meets IRS requirements"
        }
    }

    private func saveIncome() {
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

        let income = Income(
            type: selectedType,
            amount: amountDecimal,
            date: date,
            source: source.isEmpty ? nil : source,
            notes: notes.isEmpty ? nil : notes,
            isTaxable: isTaxable
        )

        modelContext.insert(income)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save income: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }
}

// MARK: - Income Type Picker Sheet

struct IncomeTypePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: IncomeType
    @Binding var isTaxable: Bool

    private var taxableTypes: [IncomeType] {
        IncomeType.allCases.filter { $0.defaultTaxable }
    }

    private var nonTaxableTypes: [IncomeType] {
        IncomeType.allCases.filter { !$0.defaultTaxable }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Taxable Income") {
                    ForEach(taxableTypes) { type in
                        incomeTypeRow(type)
                    }
                }

                Section("Non-Taxable Income") {
                    ForEach(nonTaxableTypes) { type in
                        incomeTypeRow(type)
                    }
                }
            }
            .navigationTitle("Select Income Type")
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

    @ViewBuilder
    private func incomeTypeRow(_ type: IncomeType) -> some View {
        Button {
            selectedType = type
            isTaxable = type.defaultTaxable
            dismiss()
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(TNColors.primary.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: type.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(TNColors.primary)
                }

                Text(type.rawValue)
                    .foregroundColor(TNColors.textPrimary)

                Spacer()

                if type == selectedType {
                    Image(systemName: "checkmark")
                        .foregroundColor(TNColors.primary)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AddIncomeSheet()
        .modelContainer(for: Income.self, inMemory: true)
}
