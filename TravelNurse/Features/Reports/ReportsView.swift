//
//  ReportsView.swift
//  TravelNurse
//
//  Simplified Reports & Export view with list-based layout
//

import SwiftUI
import SwiftData

/// Report type options
enum ReportType: String, CaseIterable, Identifiable {
    case annual = "Annual Summary"
    case stateBreakdown = "State Tax Breakdown"
    case expenses = "Expense Report"
    case mileage = "Mileage Log"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .annual: return "doc.text.fill"
        case .stateBreakdown: return "map.fill"
        case .expenses: return "creditcard.fill"
        case .mileage: return "car.fill"
        }
    }

    var description: String {
        switch self {
        case .annual: return "Complete year-end tax summary"
        case .stateBreakdown: return "Income and taxes by state"
        case .expenses: return "Deductible business expenses"
        case .mileage: return "Business travel mileage"
        }
    }

    var color: Color {
        switch self {
        case .annual: return TNColors.primary
        case .stateBreakdown: return TNColors.accent
        case .expenses: return TNColors.error
        case .mileage: return TNColors.success
        }
    }
}

/// Main Reports & Export view - simplified list layout
struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReportsViewModel()
    @State private var selectedReport: ReportType?
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Year Selector
                    yearSelector

                    // Quick Summary Card
                    quickSummaryCard

                    // Report Types List
                    reportTypesList

                    // Export All Section
                    exportAllSection
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadReports()
            }
            .task {
                await viewModel.loadReports()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                ExportOptionsSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TNSpacing.sm) {
                ForEach(viewModel.availableYears, id: \.self) { year in
                    Button {
                        Task {
                            await viewModel.selectYear(year)
                        }
                    } label: {
                        Text(String(year))
                            .font(TNTypography.labelMedium)
                            .foregroundColor(year == viewModel.selectedYear ? .white : TNColors.textPrimary)
                            .padding(.horizontal, TNSpacing.md)
                            .padding(.vertical, TNSpacing.sm)
                            .background(
                                year == viewModel.selectedYear
                                    ? TNColors.primary
                                    : TNColors.surface
                            )
                            .clipShape(Capsule())
                            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, TNSpacing.xs)
        }
    }

    // MARK: - Quick Summary Card

    private var quickSummaryCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                Text("\(viewModel.selectedYear) Overview")
                    .font(TNTypography.titleMedium)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: TNSpacing.lg) {
                summaryItem(
                    value: viewModel.annualSummary.formattedGrossIncome,
                    label: "Gross Income"
                )

                summaryItem(
                    value: viewModel.annualSummary.formattedTotalDeductions,
                    label: "Deductions"
                )

                summaryItem(
                    value: "\(viewModel.annualSummary.statesWorkedIn)",
                    label: "States"
                )
            }
        }
        .padding(TNSpacing.lg)
        .background(
            LinearGradient(
                colors: [TNColors.success, Color(hex: "059669")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
    }

    private func summaryItem(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.xxs) {
            Text(value)
                .font(TNTypography.titleMedium)
                .foregroundColor(.white)

            Text(label)
                .font(TNTypography.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Report Types List

    private var reportTypesList: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("AVAILABLE REPORTS")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                ForEach(ReportType.allCases) { reportType in
                    reportTypeRow(reportType)

                    if reportType != ReportType.allCases.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    private func reportTypeRow(_ reportType: ReportType) -> some View {
        NavigationLink {
            reportDetailView(for: reportType)
        } label: {
            HStack(spacing: TNSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(reportType.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: reportType.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(reportType.color)
                }

                // Info
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(reportType.rawValue)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(TNColors.textPrimary)

                    Text(reportType.description)
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(TNColors.textTertiary)
            }
            .padding(TNSpacing.md)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func reportDetailView(for reportType: ReportType) -> some View {
        switch reportType {
        case .annual:
            AnnualSummaryDetailView(viewModel: viewModel)
        case .stateBreakdown:
            StateTaxSummaryView(
                stateSummaries: viewModel.sortedStateSummaries,
                year: viewModel.selectedYear
            )
        case .expenses:
            ExpenseReportDetailView(viewModel: viewModel)
        case .mileage:
            MileageReportDetailView(viewModel: viewModel)
        }
    }

    // MARK: - Export All Section

    private var exportAllSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("EXPORT OPTIONS")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            HStack(spacing: TNSpacing.md) {
                exportButton(
                    title: "Export CSV",
                    icon: "tablecells",
                    subtitle: "For spreadsheets"
                ) {
                    Task {
                        _ = await viewModel.exportReport(format: .csv)
                    }
                }

                exportButton(
                    title: "Export PDF",
                    icon: "doc.richtext",
                    subtitle: "For records"
                ) {
                    Task {
                        _ = await viewModel.exportReport(format: .pdf)
                    }
                }
            }
        }
    }

    private func exportButton(title: String, icon: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: TNSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(TNColors.primary)

                VStack(spacing: TNSpacing.xxs) {
                    Text(title)
                        .font(TNTypography.labelMedium)
                        .foregroundColor(TNColors.textPrimary)

                    Text(subtitle)
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isExporting)
        .opacity(viewModel.isExporting ? 0.6 : 1.0)
    }
}

// MARK: - Annual Summary Detail View

struct AnnualSummaryDetailView: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: TNSpacing.lg) {
                // Income Section
                detailSection(title: "Income") {
                    detailRow("Gross Income", viewModel.annualSummary.formattedGrossIncome)
                    detailRow("Tax-Free Stipends", viewModel.annualSummary.formattedStipends, highlight: TNColors.success)
                    detailRow("Taxable Income", viewModel.annualSummary.formattedTaxableIncome, highlight: TNColors.warning)
                }

                // Deductions Section
                detailSection(title: "Deductions") {
                    detailRow("Business Expenses", viewModel.annualSummary.formattedExpenses)
                    detailRow("Mileage Deduction", viewModel.annualSummary.formattedMileageDeduction)
                    detailRow("Total Deductions", viewModel.annualSummary.formattedTotalDeductions, highlight: TNColors.success)
                }

                // Work Summary Section
                detailSection(title: "Work Summary") {
                    detailRow("Total Assignments", "\(viewModel.annualSummary.totalAssignments)")
                    detailRow("States Worked", "\(viewModel.annualSummary.statesWorkedIn)")
                    detailRow("Days Worked", "\(viewModel.annualSummary.totalDaysWorked)")
                }

                // Export Button
                Button {
                    Task {
                        _ = await viewModel.exportReport(format: .pdf)
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Annual Summary")
                    }
                    .font(TNTypography.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(TNSpacing.md)
                    .background(TNColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.bottom, TNSpacing.xl)
        }
        .background(TNColors.background)
        .navigationTitle("Annual Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text(title.uppercased())
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                content()
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    private func detailRow(_ label: String, _ value: String, highlight: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textSecondary)

            Spacer()

            Text(value)
                .font(TNTypography.titleMedium)
                .foregroundColor(highlight ?? TNColors.textPrimary)
        }
        .padding(TNSpacing.md)
    }
}

// MARK: - Expense Report Detail View

struct ExpenseReportDetailView: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: TNSpacing.lg) {
                // Summary Card
                VStack(alignment: .leading, spacing: TNSpacing.md) {
                    Text("Total Deductible Expenses")
                        .font(TNTypography.bodyMedium)
                        .foregroundColor(TNColors.textSecondary)

                    Text(viewModel.annualSummary.formattedExpenses)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(TNColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(TNSpacing.lg)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)

                // Expense Categories
                if !viewModel.topExpenseCategories.isEmpty {
                    VStack(alignment: .leading, spacing: TNSpacing.sm) {
                        Text("BY CATEGORY")
                            .font(TNTypography.caption)
                            .foregroundColor(TNColors.textSecondary)
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            ForEach(viewModel.topExpenseCategories, id: \.category) { item in
                                HStack {
                                    Image(systemName: item.category.iconName)
                                        .font(.system(size: 20))
                                        .foregroundColor(item.category.color)
                                        .frame(width: 32)

                                    Text(item.category.displayName)
                                        .font(TNTypography.bodyMedium)
                                        .foregroundColor(TNColors.textPrimary)

                                    Spacer()

                                    Text(viewModel.formatCurrency(item.amount))
                                        .font(TNTypography.titleMedium)
                                        .foregroundColor(TNColors.textPrimary)
                                }
                                .padding(TNSpacing.md)

                                if item.category != viewModel.topExpenseCategories.last?.category {
                                    Divider()
                                        .padding(.leading, 52)
                                }
                            }
                        }
                        .background(TNColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
                    }
                }

                // Export Button
                Button {
                    Task {
                        _ = await viewModel.exportReport(format: .csv)
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Expense Report")
                    }
                    .font(TNTypography.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(TNSpacing.md)
                    .background(TNColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.bottom, TNSpacing.xl)
        }
        .background(TNColors.background)
        .navigationTitle("Expense Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mileage Report Detail View

struct MileageReportDetailView: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: TNSpacing.lg) {
                // Summary Card
                VStack(alignment: .leading, spacing: TNSpacing.md) {
                    Text("Total Mileage Deduction")
                        .font(TNTypography.bodyMedium)
                        .foregroundColor(TNColors.textSecondary)

                    Text(viewModel.annualSummary.formattedMileageDeduction)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(TNColors.textPrimary)

                    Text("Based on IRS standard mileage rate")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(TNSpacing.lg)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)

                // Info Card
                VStack(alignment: .leading, spacing: TNSpacing.sm) {
                    Label("Tax Tip", systemImage: "lightbulb.fill")
                        .font(TNTypography.titleMedium)
                        .foregroundColor(TNColors.warning)

                    Text("Keep detailed mileage logs for business travel. The IRS requires documentation of date, destination, purpose, and miles driven.")
                        .font(TNTypography.bodyMedium)
                        .foregroundColor(TNColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(TNSpacing.md)
                .background(TNColors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))

                // Export Button
                Button {
                    Task {
                        _ = await viewModel.exportReport(format: .csv)
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Mileage Log")
                    }
                    .font(TNTypography.titleMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(TNSpacing.md)
                    .background(TNColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.bottom, TNSpacing.xl)
        }
        .background(TNColors.background)
        .navigationTitle("Mileage Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    ReportsView()
        .modelContainer(for: [Assignment.self, Expense.self, MileageTrip.self], inMemory: true)
}
