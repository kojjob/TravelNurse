//
//  ExpenseRow.swift
//  TravelNurse
//
//  Reusable row component for displaying expenses in lists
//

import SwiftUI

/// A styled row for displaying an expense in a list
struct ExpenseRow: View {

    let expense: Expense
    var showReceipt: Bool = true

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Category Icon
            categoryIcon

            // Details
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(expense.merchantName ?? expense.category.displayName)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: TNSpacing.xs) {
                    Text(expense.category.displayName)
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)

                    if expense.isDeductible {
                        DeductibleBadge()
                    }
                }

                Text(formattedDate)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            // Amount and Receipt Status
            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(formattedAmount)
                    .font(TNTypography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(TNColors.error) // Expenses shown in red

                if showReceipt {
                    receiptStatus
                }
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }

    // MARK: - Subviews

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(expense.category.color.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: expense.category.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(expense.category.color)
        }
    }

    private var receiptStatus: some View {
        Group {
            if expense.receipt != nil {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text("Receipt")
                        .font(TNTypography.caption)
                }
                .foregroundStyle(TNColors.success)
            } else if expense.amount >= 75 {
                HStack(spacing: 2) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                    Text("Need Receipt")
                        .font(TNTypography.caption)
                }
                .foregroundStyle(TNColors.warning)
            }
        }
    }

    // MARK: - Computed Properties

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return "-" + (formatter.string(from: expense.amount as NSDecimalNumber) ?? "$0.00")
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expense.date)
    }
}

// MARK: - Deductible Badge

struct DeductibleBadge: View {
    var body: some View {
        Text("Tax Deductible")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(TNColors.success)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(TNColors.success.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Compact Expense Row (for Recent Activity)

struct CompactExpenseRow: View {

    let expense: Expense

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: TNSpacing.radiusSM)
                    .fill(expense.category.color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: expense.category.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(expense.category.color)
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchantName ?? expense.category.displayName)
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)

                Text(relativeDate)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textTertiary)
            }

            Spacer()

            // Amount
            Text(formattedAmount)
                .font(TNTypography.titleSmall)
                .fontWeight(.semibold)
                .foregroundStyle(TNColors.error)
        }
        .padding(.vertical, TNSpacing.sm)
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return "-" + (formatter.string(from: expense.amount as NSDecimalNumber) ?? "$0.00")
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: expense.date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Expense Row") {
    VStack(spacing: TNSpacing.sm) {
        ExpenseRow(expense: .preview)
        ExpenseRow(expense: .preview)
    }
    .padding()
    .background(TNColors.background)
}

#Preview("Compact Row") {
    VStack {
        CompactExpenseRow(expense: .preview)
        Divider()
        CompactExpenseRow(expense: .preview)
    }
    .padding()
    .background(TNColors.surface)
}
