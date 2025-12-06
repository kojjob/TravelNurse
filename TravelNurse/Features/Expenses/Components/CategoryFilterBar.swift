//
//  CategoryFilterBar.swift
//  TravelNurse
//
//  Horizontal scrollable filter bar for expense categories
//

import SwiftUI

/// A horizontal scrolling bar with category filter pills
struct CategoryFilterBar: View {

    @Binding var selectedFilter: ExpenseFilterCategory
    var showGroups: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                // All filter
                CategoryFilterPill(
                    title: "All",
                    icon: "tray.full.fill",
                    isSelected: selectedFilter == .all
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = .all
                    }
                }

                // Group filters (if enabled)
                if showGroups {
                    ForEach(ExpenseGroup.allCases) { group in
                        CategoryFilterPill(
                            title: group.rawValue,
                            icon: group.iconName,
                            color: group.color,
                            isSelected: selectedFilter == .group(group)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = .group(group)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.xs)
        }
    }
}

// MARK: - Category Filter Pill

struct CategoryFilterPill: View {

    let title: String
    var icon: String? = nil
    var color: Color = TNColors.primary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TNSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(TNTypography.labelSmall)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.sm)
            .background(isSelected ? color : TNColors.surface)
            .foregroundStyle(isSelected ? .white : TNColors.textSecondary)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ExpenseGroup Extensions

extension ExpenseGroup {
    var iconName: String {
        switch self {
        case .transportation: return "car.fill"
        case .housing: return "house.fill"
        case .professional: return "briefcase.fill"
        case .technology: return "desktopcomputer"
        case .meals: return "fork.knife"
        case .taxHome: return "mappin.and.ellipse"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .transportation: return .blue
        case .housing: return .orange
        case .professional: return .purple
        case .technology: return .cyan
        case .meals: return .green
        case .taxHome: return .indigo
        case .other: return .gray
        }
    }
}

// MARK: - Year Filter Bar

struct YearFilterBar: View {

    @Binding var selectedYear: Int
    let availableYears: [Int]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(availableYears, id: \.self) { year in
                    YearPill(
                        year: year,
                        isSelected: selectedYear == year
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedYear = year
                        }
                    }
                }
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.vertical, TNSpacing.xs)
        }
    }
}

struct YearPill: View {
    let year: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(year))
                .font(TNTypography.labelMedium)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, TNSpacing.lg)
                .padding(.vertical, TNSpacing.sm)
                .background(isSelected ? TNColors.primary : TNColors.surface)
                .foregroundStyle(isSelected ? .white : TNColors.textSecondary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Stats Bar

struct ExpenseSummaryBar: View {

    let totalAmount: Decimal
    let deductibleAmount: Decimal
    let expenseCount: Int

    var body: some View {
        HStack(spacing: TNSpacing.lg) {
            StatItem(
                label: "Total",
                value: formatCurrency(totalAmount),
                color: TNColors.textPrimary
            )

            Divider()
                .frame(height: 30)

            StatItem(
                label: "Deductible",
                value: formatCurrency(deductibleAmount),
                color: TNColors.success
            )

            Divider()
                .frame(height: 30)

            StatItem(
                label: "Expenses",
                value: "\(expenseCount)",
                color: TNColors.primary
            )
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0"
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(TNTypography.titleSmall)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
        }
    }
}

// MARK: - Previews

#Preview("Category Filter Bar") {
    struct PreviewWrapper: View {
        @State private var filter: ExpenseFilterCategory = .all

        var body: some View {
            VStack(spacing: TNSpacing.lg) {
                CategoryFilterBar(selectedFilter: $filter)

                Text("Selected: \(filter.displayName)")
                    .font(TNTypography.bodyMedium)
            }
            .padding(.vertical)
            .background(TNColors.background)
        }
    }

    return PreviewWrapper()
}

#Preview("Year Filter Bar") {
    struct PreviewWrapper: View {
        @State private var year = 2024

        var body: some View {
            YearFilterBar(
                selectedYear: $year,
                availableYears: [2024, 2023, 2022]
            )
            .background(TNColors.background)
        }
    }

    return PreviewWrapper()
}

#Preview("Summary Bar") {
    ExpenseSummaryBar(
        totalAmount: 2847.50,
        deductibleAmount: 2150.00,
        expenseCount: 34
    )
    .padding()
    .background(TNColors.background)
}
