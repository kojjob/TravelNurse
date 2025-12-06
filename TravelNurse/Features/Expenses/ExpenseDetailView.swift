//
//  ExpenseDetailView.swift
//  TravelNurse
//
//  Premium detail view for viewing and editing expenses
//

import SwiftUI

/// Detailed expense view with edit and delete capabilities
struct ExpenseDetailView: View {

    @Environment(\.dismiss) private var dismiss
    let expense: Expense
    let onUpdate: (Expense) -> Void
    let onDelete: () -> Void

    // MARK: - State

    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var showingReceiptScanner = false

    // Edit state
    @State private var editCategory: ExpenseCategory
    @State private var editAmount: Decimal
    @State private var editAmountText: String
    @State private var editDate: Date
    @State private var editMerchantName: String
    @State private var editNotes: String
    @State private var editIsDeductible: Bool
    @State private var showingCategoryPicker = false
    @State private var selectedGroup: ExpenseGroup

    init(expense: Expense, onUpdate: @escaping (Expense) -> Void, onDelete: @escaping () -> Void) {
        self.expense = expense
        self.onUpdate = onUpdate
        self.onDelete = onDelete

        _editCategory = State(initialValue: expense.category)
        _editAmount = State(initialValue: expense.amount)
        _editAmountText = State(initialValue: (expense.amount as NSDecimalNumber).stringValue)
        _editDate = State(initialValue: expense.date)
        _editMerchantName = State(initialValue: expense.merchantName ?? "")
        _editNotes = State(initialValue: expense.notes ?? "")
        _editIsDeductible = State(initialValue: expense.isDeductible)
        _selectedGroup = State(initialValue: expense.category.group)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    if isEditing {
                        editingContent
                    } else {
                        viewingContent
                    }
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle(isEditing ? "Edit Expense" : "Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .foregroundStyle(TNColors.textSecondary)
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundStyle(TNColors.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(TNColors.primary)
                    } else {
                        Menu {
                            Button {
                                isEditing = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(TNColors.primary)
                        }
                    }
                }
            }
            .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this expense? This action cannot be undone.")
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(
                    selectedCategory: $editCategory,
                    selectedGroup: $selectedGroup
                )
            }
            .sheet(isPresented: $showingReceiptScanner) {
                ReceiptScannerView { result in
                    handleScannedReceipt(result)
                }
            }
        }
    }

    // MARK: - Viewing Content

    private var viewingContent: some View {
        VStack(spacing: TNSpacing.lg) {
            // Amount Header
            amountHeaderView

            // Details Card
            detailsCardView

            // Receipt Section
            receiptCardView

            // Metadata Card
            metadataCardView
        }
    }

    private var amountHeaderView: some View {
        VStack(spacing: TNSpacing.md) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: expense.category.iconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(expense.category.color)
            }

            // Amount
            Text(expense.amountFormatted)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(TNColors.error)

            // Category & Date
            VStack(spacing: TNSpacing.xxs) {
                Text(expense.category.displayName)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text(expense.dateFormatted)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textSecondary)
            }

            // Status Badges
            HStack(spacing: TNSpacing.sm) {
                if expense.isDeductible {
                    StatusBadge(
                        title: "Tax Deductible",
                        icon: "checkmark.seal.fill",
                        color: TNColors.success
                    )
                }

                if expense.hasReceipt {
                    StatusBadge(
                        title: "Receipt Attached",
                        icon: "doc.text.fill",
                        color: TNColors.primary
                    )
                } else if expense.amount >= 75 {
                    StatusBadge(
                        title: "Needs Receipt",
                        icon: "exclamationmark.triangle.fill",
                        color: TNColors.warning
                    )
                }
            }
        }
        .padding(TNSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private var detailsCardView: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Details")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            VStack(spacing: 0) {
                // Merchant
                ExpenseDetailRow(
                    icon: "building.2",
                    label: "Merchant",
                    value: expense.merchantName ?? "Not specified"
                )

                Divider()
                    .padding(.leading, 48)

                // Category Group
                ExpenseDetailRow(
                    icon: "folder",
                    label: "Group",
                    value: expense.category.group.rawValue
                )

                if let notes = expense.notes, !notes.isEmpty {
                    Divider()
                        .padding(.leading, 48)

                    // Notes
                    ExpenseDetailRow(
                        icon: "note.text",
                        label: "Notes",
                        value: notes
                    )
                }

                Divider()
                    .padding(.leading, 48)

                // Tax Year
                ExpenseDetailRow(
                    icon: "calendar",
                    label: "Tax Year",
                    value: String(expense.taxYear)
                )
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
    }

    private var receiptCardView: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Receipt")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            if expense.hasReceipt {
                // Receipt thumbnail placeholder
                HStack(spacing: TNSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: TNSpacing.radiusSM)
                            .fill(TNColors.success.opacity(0.1))
                            .frame(width: 60, height: 80)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(TNColors.success)
                    }

                    VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                        Text("Receipt Attached")
                            .font(TNTypography.titleSmall)
                            .foregroundStyle(TNColors.textPrimary)

                        Text("Tap to view full receipt")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(TNColors.textTertiary)
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            } else {
                Button {
                    showingReceiptScanner = true
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: TNSpacing.radiusSM)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundStyle(TNColors.border)
                                .frame(width: 60, height: 80)

                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundStyle(TNColors.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                            Text("Add Receipt")
                                .font(TNTypography.titleSmall)
                                .foregroundStyle(TNColors.textPrimary)

                            Text(expense.amount >= 75 ? "Required for IRS documentation" : "Optional for this amount")
                                .font(TNTypography.caption)
                                .foregroundStyle(expense.amount >= 75 ? TNColors.warning : TNColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(TNColors.textTertiary)
                    }
                    .padding(TNSpacing.md)
                    .background(TNColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var metadataCardView: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Record Info")
                .font(TNTypography.labelMedium)
                .foregroundStyle(TNColors.textSecondary)

            VStack(spacing: 0) {
                ExpenseDetailRow(
                    icon: "clock",
                    label: "Created",
                    value: formatDate(expense.createdAt)
                )

                Divider()
                    .padding(.leading, 48)

                ExpenseDetailRow(
                    icon: "arrow.clockwise",
                    label: "Updated",
                    value: formatDate(expense.updatedAt)
                )

                if expense.isReported {
                    Divider()
                        .padding(.leading, 48)

                    ExpenseDetailRow(
                        icon: "checkmark.circle",
                        label: "Status",
                        value: "Reported"
                    )
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
    }

    // MARK: - Editing Content

    private var editingContent: some View {
        VStack(spacing: TNSpacing.lg) {
            // Amount Entry
            VStack(spacing: TNSpacing.md) {
                Text("Amount")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(TNColors.textPrimary)

                    TextField("0.00", text: $editAmountText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(TNColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .onChange(of: editAmountText) { _, newValue in
                            parseAmount(newValue)
                        }
                }
            }
            .padding(TNSpacing.xl)
            .background(TNColors.error.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))

            // Category Selection
            VStack(alignment: .leading, spacing: TNSpacing.sm) {
                Text("Category")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textSecondary)

                Button {
                    showingCategoryPicker = true
                } label: {
                    HStack(spacing: TNSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(editCategory.color.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: editCategory.iconName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(editCategory.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(editCategory.displayName)
                                .font(TNTypography.titleSmall)
                                .foregroundStyle(TNColors.textPrimary)

                            Text(editCategory.group.rawValue)
                                .font(TNTypography.caption)
                                .foregroundStyle(TNColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(TNColors.textTertiary)
                    }
                    .padding(TNSpacing.md)
                    .background(TNColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
                .buttonStyle(.plain)
            }

            // Date Picker
            VStack(alignment: .leading, spacing: TNSpacing.sm) {
                Text("Date")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textSecondary)

                DatePicker("", selection: $editDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(TNSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TNColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }

            // Details
            VStack(alignment: .leading, spacing: TNSpacing.sm) {
                Text("Details")
                    .font(TNTypography.labelMedium)
                    .foregroundStyle(TNColors.textSecondary)

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundStyle(TNColors.textTertiary)
                            .frame(width: 24)

                        TextField("Merchant Name", text: $editMerchantName)
                    }
                    .padding(TNSpacing.md)

                    Divider()
                        .padding(.leading, 48)

                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundStyle(TNColors.textTertiary)
                            .frame(width: 24)

                        TextField("Notes", text: $editNotes, axis: .vertical)
                            .lineLimit(3...5)
                    }
                    .padding(TNSpacing.md)
                }
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            }

            // Tax Deductible Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax Deductible")
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.textPrimary)

                    Text("Mark if this expense qualifies")
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $editIsDeductible)
                    .labelsHidden()
                    .tint(TNColors.success)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        }
    }

    // MARK: - Helper Methods

    private func handleScannedReceipt(_ result: ScannedReceiptResult) {
        // Update the expense with scanned receipt data
        // In a production app, you'd save the image to persistent storage
        // and the hasReceipt property would be computed based on whether receiptImageData exists
        
        // For now, we'll just call onUpdate to trigger any necessary updates
        // The actual receipt attachment would be handled by setting expense.receiptImageData
        
        // Optionally update other fields if they were detected
        if !isEditing {
            // If viewing mode and merchant was detected, could show a prompt to update
        }
        
        onUpdate(expense)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseAmount(_ text: String) {
        let cleanedText = text.replacingOccurrences(of: ",", with: ".")
        if let value = Decimal(string: cleanedText) {
            editAmount = value
        } else if text.isEmpty {
            editAmount = 0
        }
    }

    private func cancelEditing() {
        // Reset to original values
        editCategory = expense.category
        editAmount = expense.amount
        editAmountText = (expense.amount as NSDecimalNumber).stringValue
        editDate = expense.date
        editMerchantName = expense.merchantName ?? ""
        editNotes = expense.notes ?? ""
        editIsDeductible = expense.isDeductible
        selectedGroup = expense.category.group
        isEditing = false
    }

    private func saveChanges() {
        // Update expense properties
        expense.category = editCategory
        expense.amount = editAmount
        expense.date = editDate
        expense.merchantName = editMerchantName.isEmpty ? nil : editMerchantName.trimmingCharacters(in: .whitespaces)
        expense.notes = editNotes.isEmpty ? nil : editNotes.trimmingCharacters(in: .whitespaces)
        expense.isDeductible = editIsDeductible
        expense.taxYear = Calendar.current.component(.year, from: editDate)
        expense.updatedAt = Date()

        onUpdate(expense)
        isEditing = false
    }
}

// MARK: - Supporting Views

private struct ExpenseDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(TNColors.textTertiary)
                .frame(width: 24)

            Text(label)
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textSecondary)

            Spacer()

            Text(value)
                .font(TNTypography.bodyMedium)
                .foregroundStyle(TNColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(TNSpacing.md)
    }
}

private struct StatusBadge: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: TNSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))

            Text(title)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, TNSpacing.sm)
        .padding(.vertical, TNSpacing.xxs)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Expense Detail") {
    ExpenseDetailView(
        expense: .preview,
        onUpdate: { _ in },
        onDelete: {}
    )
}

#Preview("Expense Detail - Editing") {
    ExpenseDetailView(
        expense: .preview,
        onUpdate: { _ in },
        onDelete: {}
    )
}
