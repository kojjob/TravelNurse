//
//  ReportsView.swift
//  TravelNurse
//
//  Tax reports view with annual summaries and state breakdowns
//

import SwiftUI
import SwiftData

/// Main reports view showing annual tax summaries and state breakdowns
struct ReportsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReportsViewModel()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 4)...currentYear).reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Year Selector
                    yearSelectorSection

                    // Summary Cards
                    summaryCardsSection

                    // State Tax Breakdown
                    stateTaxSection

                    // Quick Actions
                    quickActionsSection
                }
                .padding(TNSpacing.md)
            }
            .background(TNColors.background)
            .navigationTitle("Reports")
            .onAppear {
                viewModel.loadData(for: selectedYear)
            }
            .onChange(of: selectedYear) { _, newYear in
                viewModel.loadData(for: newYear)
            }
        }
    }

    // MARK: - Year Selector Section

    private var yearSelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedYear = year
                        }
                    } label: {
                        Text(String(year))
                            .font(TNTypography.labelMedium)
                            .fontWeight(selectedYear == year ? .semibold : .medium)
                            .foregroundStyle(selectedYear == year ? .white : TNColors.textSecondary)
                            .padding(.horizontal, TNSpacing.lg)
                            .padding(.vertical, TNSpacing.sm)
                            .background(selectedYear == year ? TNColors.primary : TNColors.surface)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        VStack(spacing: TNSpacing.md) {
            // Total Income Card
            ReportSummaryCard(
                title: "Total Income",
                value: viewModel.formattedTotalIncome,
                subtitle: "Gross earnings for \(selectedYear)",
                icon: "dollarsign.circle.fill",
                color: TNColors.success,
                isLarge: true
            )

            HStack(spacing: TNSpacing.md) {
                // Total Expenses
                ReportSummaryCard(
                    title: "Expenses",
                    value: viewModel.formattedTotalExpenses,
                    subtitle: "Tax deductible",
                    icon: "creditcard.fill",
                    color: TNColors.primary
                )

                // Mileage Deduction
                ReportSummaryCard(
                    title: "Mileage",
                    value: viewModel.formattedMileageDeduction,
                    subtitle: "\(String(format: "%.0f", viewModel.totalMiles)) miles",
                    icon: "car.fill",
                    color: TNColors.accent
                )
            }
        }
    }

    // MARK: - State Tax Section

    private var stateTaxSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("State Tax Breakdown")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            if viewModel.stateBreakdowns.isEmpty {
                emptyStateBreakdown
            } else {
                VStack(spacing: TNSpacing.xs) {
                    ForEach(viewModel.stateBreakdowns, id: \.state) { breakdown in
                        StateBreakdownRow(breakdown: breakdown)
                    }
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }

    private var emptyStateBreakdown: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "map")
                .font(.system(size: 32))
                .foregroundStyle(TNColors.textTertiary)

            Text("No State Data")
                .font(TNTypography.titleMedium)
                .foregroundStyle(TNColors.textSecondary)

            Text("Complete assignments to see state-by-state earnings")
                .font(TNTypography.caption)
                .foregroundStyle(TNColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.xl)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("Export Options")
                .font(TNTypography.headlineMedium)
                .foregroundStyle(TNColors.textPrimary)

            VStack(spacing: TNSpacing.sm) {
                ReportActionButton(
                    title: "Export to CSV",
                    subtitle: "Download spreadsheet format",
                    icon: "tablecells",
                    action: { viewModel.exportToCSV(year: selectedYear) }
                )

                ReportActionButton(
                    title: "Generate PDF Report",
                    subtitle: "Complete tax summary document",
                    icon: "doc.text.fill",
                    action: { viewModel.generatePDFReport(year: selectedYear) }
                )

                ReportActionButton(
                    title: "Share with Accountant",
                    subtitle: "Email or share via other apps",
                    icon: "square.and.arrow.up",
                    action: { viewModel.shareReport(year: selectedYear) }
                )
            }
        }
    }
}

// MARK: - Report Summary Card

struct ReportSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 24 : 18))
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(value)
                    .font(isLarge ? TNTypography.displayMedium : TNTypography.titleLarge)
                    .foregroundStyle(color)

                Text(title)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text(subtitle)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - State Breakdown Row

struct StateBreakdownRow: View {
    let breakdown: StateBreakdown

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(breakdown.state.displayName)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.textPrimary)

                Text("\(breakdown.weeksWorked) weeks worked")
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(breakdown.formattedEarnings)
                    .font(TNTypography.titleSmall)
                    .foregroundStyle(TNColors.success)

                HStack(spacing: TNSpacing.xxs) {
                    Circle()
                        .fill(breakdown.hasStateTax ? TNColors.warning : TNColors.success)
                        .frame(width: 6, height: 6)

                    Text(breakdown.hasStateTax ? "State tax applies" : "No state tax")
                        .font(TNTypography.caption)
                        .foregroundStyle(breakdown.hasStateTax ? TNColors.warning : TNColors.success)
                }
            }
        }
        .padding(.vertical, TNSpacing.xs)
    }
}

// MARK: - Report Action Button

struct ReportActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TNSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(TNColors.primary)
                    .frame(width: 40, height: 40)
                    .background(TNColors.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))

                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(title)
                        .font(TNTypography.titleSmall)
                        .foregroundStyle(TNColors.textPrimary)

                    Text(subtitle)
                        .font(TNTypography.caption)
                        .foregroundStyle(TNColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TNColors.textTertiary)
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ReportsView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
