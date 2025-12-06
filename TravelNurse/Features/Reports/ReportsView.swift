//
//  ReportsView.swift
//  TravelNurse
//
//  Main Reports & Export view with annual summary and state breakdown
//

import SwiftUI
import SwiftData

/// Main Reports & Export view
struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReportsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Year Selector
                    yearSelector

                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // Annual Summary Card
                        annualSummaryCard

                        // Key Metrics Grid
                        keyMetricsGrid

                        // State Breakdown Section
                        stateBreakdownSection

                        // Expense Breakdown Section
                        expenseBreakdownSection

                        // Export Section
                        exportSection
                    }
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Tax Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(TNColors.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                ExportOptionsSheet(viewModel: viewModel)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Export Complete", isPresented: $viewModel.showExportSuccess) {
                Button("OK") {
                    viewModel.dismissExportSuccess()
                }
            } message: {
                Text(viewModel.exportSuccessMessage ?? "Report exported successfully")
            }
            .task {
                await viewModel.loadReports()
            }
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    yearButton(year)
                }
            }
            .padding(.horizontal, TNSpacing.xs)
        }
    }

    private func yearButton(_ year: Int) -> some View {
        Button {
            Task {
                await viewModel.selectYear(year)
            }
        } label: {
            Text(String(year))
                .font(TNTypography.titleMedium)
                .foregroundColor(year == viewModel.selectedYear ? .white : TNColors.textPrimary)
                .padding(.horizontal, TNSpacing.md)
                .padding(.vertical, TNSpacing.sm)
                .background(
                    Capsule()
                        .fill(year == viewModel.selectedYear ? TNColors.primary : TNColors.surface)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(year == viewModel.selectedYear ? Color.clear : TNColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: TNSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading reports...")
                .font(TNTypography.bodyLarge)
                .foregroundColor(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.xxxl)
    }

    // MARK: - Annual Summary Card

    private var annualSummaryCard: some View {
        VStack(spacing: TNSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                    Text("\(viewModel.selectedYear) Tax Summary")
                        .font(TNTypography.headlineLarge)
                        .foregroundColor(TNColors.textPrimary)

                    Text("\(viewModel.annualSummary.totalAssignments) assignments · \(viewModel.annualSummary.statesWorkedIn) states")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28))
                    .foregroundColor(TNColors.primary)
            }

            Divider()

            // Income Summary
            VStack(spacing: TNSpacing.sm) {
                summaryRow(
                    label: "Gross Income",
                    value: viewModel.annualSummary.formattedGrossIncome,
                    color: TNColors.textPrimary
                )

                summaryRow(
                    label: "Tax-Free Stipends",
                    value: viewModel.annualSummary.formattedStipends,
                    color: TNColors.success,
                    isHighlighted: true
                )

                summaryRow(
                    label: "Taxable Income",
                    value: viewModel.annualSummary.formattedTaxableIncome,
                    color: TNColors.warning
                )
            }

            Divider()

            // Deductions Summary
            VStack(spacing: TNSpacing.sm) {
                summaryRow(
                    label: "Business Expenses",
                    value: viewModel.annualSummary.formattedExpenses,
                    color: TNColors.textSecondary
                )

                summaryRow(
                    label: "Mileage Deduction",
                    value: viewModel.annualSummary.formattedMileageDeduction,
                    color: TNColors.textSecondary
                )

                summaryRow(
                    label: "Total Deductions",
                    value: viewModel.annualSummary.formattedTotalDeductions,
                    color: TNColors.success,
                    isHighlighted: true
                )
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
    }

    private func summaryRow(label: String, value: String, color: Color, isHighlighted: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(TNTypography.bodyLarge)
                .foregroundColor(TNColors.textSecondary)

            Spacer()

            Text(value)
                .font(isHighlighted ? TNTypography.titleMedium : TNTypography.bodyLarge)
                .foregroundColor(color)
        }
    }

    // MARK: - Key Metrics Grid

    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: TNSpacing.sm),
            GridItem(.flexible(), spacing: TNSpacing.sm)
        ], spacing: TNSpacing.sm) {
            metricCard(
                icon: "calendar",
                title: "Days Worked",
                value: "\(viewModel.annualSummary.totalDaysWorked)",
                color: TNColors.primary
            )

            metricCard(
                icon: "briefcase.fill",
                title: "Assignments",
                value: "\(viewModel.annualSummary.totalAssignments)",
                color: TNColors.accent
            )

            metricCard(
                icon: "map.fill",
                title: "States",
                value: "\(viewModel.annualSummary.statesWorkedIn)",
                color: TNColors.secondary
            )

            metricCard(
                icon: "dollarsign.circle.fill",
                title: "Avg/Assignment",
                value: averagePerAssignment,
                color: TNColors.success
            )
        }
    }

    private var averagePerAssignment: String {
        guard viewModel.annualSummary.totalAssignments > 0 else { return "$0" }
        let average = viewModel.annualSummary.totalGrossIncome / Decimal(viewModel.annualSummary.totalAssignments)
        return viewModel.formatCurrency(average)
    }

    private func metricCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(TNTypography.titleLarge)
                .foregroundColor(TNColors.textPrimary)

            Text(title)
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
    }

    // MARK: - State Breakdown Section

    private var stateBreakdownSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            sectionHeader(title: "Income by State", icon: "map")

            if viewModel.sortedStateSummaries.isEmpty {
                emptyStateView(message: "No state data available")
            } else {
                VStack(spacing: TNSpacing.sm) {
                    ForEach(viewModel.sortedStateSummaries.prefix(5)) { summary in
                        stateRow(summary)
                    }

                    if viewModel.sortedStateSummaries.count > 5 {
                        NavigationLink {
                            StateTaxSummaryView(
                                stateSummaries: viewModel.sortedStateSummaries,
                                year: viewModel.selectedYear
                            )
                        } label: {
                            HStack {
                                Text("View All \(viewModel.sortedStateSummaries.count) States")
                                    .font(TNTypography.titleMedium)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(TNColors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TNSpacing.sm)
                        }
                    }
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
            }
        }
    }

    private func stateRow(_ summary: StateTaxSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                HStack(spacing: TNSpacing.xs) {
                    Text(summary.state.rawValue)
                        .font(TNTypography.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, TNSpacing.xs)
                        .padding(.vertical, 2)
                        .background(TNColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text(summary.state.fullName)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(TNColors.textPrimary)
                }

                Text("\(summary.daysWorked) days · \(summary.assignments.count) assignments")
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(summary.formattedGrossIncome)
                    .font(TNTypography.titleMedium)
                    .foregroundColor(TNColors.textPrimary)

                if summary.state.hasNoIncomeTax {
                    Text("No State Tax")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.success)
                }
            }
        }
        .padding(.vertical, TNSpacing.xs)
    }

    // MARK: - Expense Breakdown Section

    private var expenseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            sectionHeader(title: "Expense Categories", icon: "creditcard")

            if viewModel.topExpenseCategories.isEmpty {
                emptyStateView(message: "No expenses recorded")
            } else {
                VStack(spacing: TNSpacing.sm) {
                    ForEach(viewModel.topExpenseCategories, id: \.category) { item in
                        expenseRow(category: item.category, amount: item.amount)
                    }
                }
                .padding(TNSpacing.md)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
            }
        }
    }

    private func expenseRow(category: ExpenseCategory, amount: Decimal) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .font(.system(size: 20))
                .foregroundColor(category.color)
                .frame(width: 32)

            Text(category.displayName)
                .font(TNTypography.bodyLarge)
                .foregroundColor(TNColors.textPrimary)

            Spacer()

            Text(viewModel.formatCurrency(amount))
                .font(TNTypography.titleMedium)
                .foregroundColor(TNColors.textPrimary)
        }
        .padding(.vertical, TNSpacing.xs)
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            sectionHeader(title: "Export Report", icon: "square.and.arrow.up")

            HStack(spacing: TNSpacing.md) {
                exportButton(format: .csv)
                exportButton(format: .pdf)
            }
        }
    }

    private func exportButton(format: ExportFormat) -> some View {
        Button {
            Task {
                if let url = await viewModel.exportReport(format: format) {
                    shareReport(url: url)
                }
            }
        } label: {
            HStack {
                Image(systemName: format.iconName)
                    .font(.system(size: 20))
                Text(format.rawValue)
                    .font(TNTypography.titleMedium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TNSpacing.md)
            .background(TNColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isExporting)
        .opacity(viewModel.isExporting ? 0.6 : 1.0)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: TNSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(TNColors.primary)
            Text(title)
                .font(TNTypography.headlineLarge)
                .foregroundColor(TNColors.textPrimary)
        }
    }

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(TNColors.textTertiary)
            Text(message)
                .font(TNTypography.bodyLarge)
                .foregroundColor(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }

    // MARK: - Actions

    private func shareReport(url: URL) {
        // Share functionality would go here
        // Using UIActivityViewController in production
    }
}

// MARK: - Preview

#Preview {
    ReportsView()
        .modelContainer(for: [Assignment.self, Expense.self, MileageTrip.self])
}
