//
//  AddExpenseView.swift
//  TravelNurse
//
//  Premium form for adding tax-deductible expenses
//

import SwiftUI

/// Premium expense entry form with category selection and receipt capture
struct AddExpenseView: View {

    @Environment(\.dismiss) private var dismiss
    let onSave: (Expense) -> Void

    // MARK: - Form State

    @State private var selectedCategory: ExpenseCategory = .meals
    @State private var amount: Decimal = 0
    @State private var amountText = ""
    @State private var date = Date()
    @State private var merchantName = ""
    @State private var notes = ""
    @State private var isDeductible = true
    @State private var showingReceiptScanner = false
    @State private var scannedReceiptImage: UIImage?

    // Validation
    @State private var showingValidationError = false
    @State private var validationMessage = ""

    // Category picker state
    @State private var selectedGroup: ExpenseGroup = .meals
    @State private var showingCategoryPicker = false

    // OCR auto-fill feedback
    @State private var showingOCRSuccess = false
    @State private var ocrFieldsPopulated: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Amount Entry Card
                    amountCard

                    // Category Selection
                    categorySection

                    // Details Section
                    detailsSection

                    // Tax Deductible Toggle
                    deductibleSection

                    // Receipt Section
                    receiptSection
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(TNColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isFormValid ? TNColors.primary : TNColors.textTertiary)
                    .disabled(!isFormValid)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(
                    selectedCategory: $selectedCategory,
                    selectedGroup: $selectedGroup
                )
            }
            .sheet(isPresented: $showingReceiptScanner) {
                ReceiptScannerView { result in
                    handleScannedReceipt(result)
                }
            }
            .overlay {
                if showingOCRSuccess {
                    ocrSuccessToast
                }
            }
        }
    }

    // MARK: - Amount Card

    private var amountCard: some View {
        VStack(spacing: TNSpacing.md) {
            Text("Amount")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(TNColors.textPrimary)

                TextField("0.00", text: $amountText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(TNColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .onChange(of: amountText) { _, newValue in
                        parseAmount(newValue)
                    }
            }
            .frame(maxWidth: .infinity)

            DatePicker(
                "Date",
                selection: $date,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding(.horizontal, TNSpacing.lg)
            .padding(.vertical, TNSpacing.sm)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
        }
        .padding(TNSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [TNColors.error.opacity(0.1), TNColors.error.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Category")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            Button {
                showingCategoryPicker = true
            } label: {
                HStack(spacing: TNSpacing.md) {
                    // Category Icon
                    ZStack {
                        Circle()
                            .fill(selectedCategory.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: selectedCategory.iconName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(selectedCategory.color)
                    }

                    // Category Details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCategory.displayName)
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(TNColors.textPrimary)

                        Text(selectedCategory.group.rawValue)
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(TNColors.textTertiary)
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Details")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            VStack(spacing: 0) {
                // Merchant Name
                HStack {
                    Image(systemName: "building.2")
                        .font(.system(size: 16))
                        .foregroundStyle(TNColors.textTertiary)
                        .frame(width: 24)

                    TextField("Merchant Name", text: $merchantName)
                        .font(TNTypography.bodyMedium)
                }
                .padding(TNSpacing.md)

                Divider()
                    .padding(.leading, TNSpacing.md + 24 + TNSpacing.sm)

                // Notes
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundStyle(TNColors.textTertiary)
                        .frame(width: 24)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .font(TNTypography.bodyMedium)
                        .lineLimit(3...5)
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
    }

    // MARK: - Deductible Section

    private var deductibleSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax Deductible")
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.textPrimary)

                    Text("Mark if this expense qualifies for tax deduction")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $isDeductible)
                    .labelsHidden()
                    .tint(TNColors.success)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
    }

    // MARK: - Receipt Section

    private var receiptSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Text("Receipt")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textSecondary)

                Spacer()

                if scannedReceiptImage != nil {
                    Label("Attached", systemImage: "checkmark.circle.fill")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.success)
                } else if amount >= 75 {
                    Label("Recommended", systemImage: "info.circle.fill")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.warning)
                }
            }

            // Show scanned receipt preview or scan button
            if let receiptImage = scannedReceiptImage {
                // Scanned Receipt Preview
                VStack(spacing: TNSpacing.sm) {
                    Image(uiImage: receiptImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                                .strokeBorder(TNColors.border, lineWidth: 1)
                        )

                    HStack(spacing: TNSpacing.md) {
                        Button {
                            showingReceiptScanner = true
                        } label: {
                            HStack(spacing: TNSpacing.xs) {
                                Image(systemName: "arrow.clockwise")
                                Text("Rescan")
                            }
                            .font(TNTypography.labelSmall)
                            .foregroundStyle(TNColors.primary)
                        }

                        Spacer()

                        Button {
                            scannedReceiptImage = nil
                        } label: {
                            HStack(spacing: TNSpacing.xs) {
                                Image(systemName: "trash")
                                Text("Remove")
                            }
                            .font(TNTypography.labelSmall)
                            .foregroundStyle(TNColors.error)
                        }
                    }
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            } else {
                // Scan Receipt Button
                Button {
                    showingReceiptScanner = true
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: TNSpacing.radiusSM)
                                .fill(TNColors.primary.opacity(0.1))
                                .frame(width: 56, height: 56)

                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(TNColors.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan Receipt")
                                .font(TNTypography.titleSmall)
                                .foregroundStyle(TNColors.textPrimary)

                            Text("Use camera to capture and extract data")
                                .font(TNTypography.caption)
                                .foregroundStyle(TNColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(TNColors.textTertiary)
                    }
                    .padding(TNSpacing.md)
                    .background(TNColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }

            // IRS Receipt Warning
            if amount >= 75 && scannedReceiptImage == nil {
                HStack(spacing: TNSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(TNColors.warning)

                    Text("IRS requires receipts for expenses $75 and over")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }
                .padding(TNSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TNColors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        amount > 0
    }

    // MARK: - OCR Success Toast

    private var ocrSuccessToast: some View {
        VStack {
            Spacer()

            HStack(spacing: TNSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(TNColors.success)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Receipt Scanned")
                        .font(TNTypography.labelSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(TNColors.textPrimary)

                    Text(ocrFieldsPopulated.joined(separator: ", ") + " auto-filled")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal, TNSpacing.lg)
            .padding(.bottom, TNSpacing.xl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingOCRSuccess)
    }

    // MARK: - Helper Methods

    private func handleScannedReceipt(_ result: ScannedReceiptResult) {
        var populatedFields: [String] = []

        // Auto-fill merchant name
        if let merchant = result.merchantName, !merchant.isEmpty {
            merchantName = merchant
            populatedFields.append("Merchant")
        }

        // Auto-fill amount
        if let scannedAmount = result.amount, scannedAmount > 0 {
            amount = scannedAmount
            amountText = formatDecimalForInput(scannedAmount)
            populatedFields.append("Amount")
        }

        // Auto-fill date
        if let scannedDate = result.date {
            date = scannedDate
            populatedFields.append("Date")
        }

        // Store scanned image for receipt attachment
        scannedReceiptImage = result.image

        // Show success feedback
        if !populatedFields.isEmpty {
            ocrFieldsPopulated = populatedFields
            showingOCRSuccess = true

            // Auto-hide toast after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showingOCRSuccess = false
                }
            }
        }
    }

    private func formatDecimalForInput(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }

    private func parseAmount(_ text: String) {
        let cleanedText = text.replacingOccurrences(of: ",", with: ".")
        if let value = Decimal(string: cleanedText) {
            amount = value
        } else if text.isEmpty {
            amount = 0
        }
    }

    private func saveExpense() {
        guard isFormValid else {
            validationMessage = "Please enter a valid amount."
            showingValidationError = true
            return
        }

        let expense = Expense(
            category: selectedCategory,
            amount: amount,
            date: date,
            merchantName: merchantName.isEmpty ? nil : merchantName.trimmingCharacters(in: .whitespaces),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            isDeductible: isDeductible
        )

        onSave(expense)
        dismiss()
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ExpenseCategory
    @Binding var selectedGroup: ExpenseGroup

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Group Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: TNSpacing.sm) {
                            ForEach(ExpenseGroup.allCases) { group in
                                GroupPill(
                                    group: group,
                                    isSelected: selectedGroup == group
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedGroup = group
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, TNSpacing.md)
                    }

                    // Categories Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: TNSpacing.sm),
                            GridItem(.flexible(), spacing: TNSpacing.sm)
                        ],
                        spacing: TNSpacing.sm
                    ) {
                        ForEach(selectedGroup.categories, id: \.self) { category in
                            CategoryCard(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, TNSpacing.md)
                }
                .padding(.vertical, TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Group Pill

struct GroupPill: View {

    let group: ExpenseGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TNSpacing.xs) {
                Image(systemName: group.iconName)
                    .font(.system(size: 12, weight: .medium))

                Text(group.rawValue)
                    .font(TNTypography.labelSmall)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.sm)
            .background(isSelected ? group.color : TNColors.surface)
            .foregroundStyle(isSelected ? .white : TNColors.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? group.color : TNColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Card

struct CategoryCard: View {

    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: TNSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(category.color)
                }

                Text(category.displayName)
                    .font(TNTypography.labelSmall)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(TNSpacing.md)
            .background(isSelected ? category.color.opacity(0.1) : TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: TNSpacing.radiusMD)
                    .strokeBorder(isSelected ? category.color : TNColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Add Expense") {
    AddExpenseView { expense in
        print("Created expense: \(expense.category.displayName) - \(expense.amount)")
    }
}

#Preview("Category Picker") {
    CategoryPickerSheet(
        selectedCategory: .constant(.meals),
        selectedGroup: .constant(.meals)
    )
}
