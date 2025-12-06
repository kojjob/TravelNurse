//
//  TaxesView.swift
//  TravelNurse
//
//  Taxes tab with quarterly payment tracking and tax estimates
//

import SwiftUI
import SwiftData

/// Main taxes view with quarterly tracking and tax breakdown
struct TaxesView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaxesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Year Selector
                    yearSelector

                    // Tax Summary Card
                    taxSummaryCard

                    // Payment Progress
                    paymentProgressSection

                    // Quarterly Payments
                    quarterlyPaymentsSection

                    // Tax Breakdown
                    taxBreakdownSection

                    // Income Summary
                    incomeSummarySection
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Taxes")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
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

    // MARK: - Tax Summary Card

    private var taxSummaryCard: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                Text("\(viewModel.selectedYear) Estimated Tax")
                    .font(TNTypography.bodyMedium)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if let days = viewModel.daysUntilNextPayment {
                    HStack(spacing: TNSpacing.xs) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("\(days) days")
                            .font(TNTypography.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, TNSpacing.sm)
                    .padding(.vertical, TNSpacing.xxs)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }

            Text(viewModel.formattedTotalEstimatedTax)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Progress bar
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                HStack {
                    Text("Paid: \(viewModel.formattedTotalPaidTax)")
                        .font(TNTypography.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    Text("Remaining: \(viewModel.formattedRemainingTax)")
                        .font(TNTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * viewModel.paymentProgress, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Quick Stats
            HStack(spacing: TNSpacing.md) {
                quickStatPill(
                    title: "Quarterly",
                    value: viewModel.quarterlyTaxes.first?.formattedEstimatedAmount ?? "$0"
                )

                quickStatPill(
                    title: "Next Due",
                    value: viewModel.nextDueQuarter?.formattedDueDate ?? "N/A"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.lg)
        .background(
            LinearGradient(
                colors: [TNColors.accent, Color(hex: "6D28D9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
    }

    private func quickStatPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.xxs) {
            Text(title)
                .font(TNTypography.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(TNTypography.titleSmall)
                .foregroundColor(.white)
        }
        .padding(.horizontal, TNSpacing.md)
        .padding(.vertical, TNSpacing.sm)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusSM))
    }

    // MARK: - Payment Progress Section

    private var paymentProgressSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("PAYMENT PROGRESS")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            HStack(spacing: TNSpacing.sm) {
                // Paid quarters count
                progressCard(
                    icon: "checkmark.circle.fill",
                    iconColor: TNColors.success,
                    title: "Paid",
                    value: "\(viewModel.quarterlyTaxes.filter { $0.isPaid }.count)/4"
                )

                // Pending quarters count
                progressCard(
                    icon: "clock.fill",
                    iconColor: TNColors.warning,
                    title: "Pending",
                    value: "\(viewModel.quarterlyTaxes.filter { !$0.isPaid }.count)"
                )

                // Payment percentage
                progressCard(
                    icon: "percent",
                    iconColor: TNColors.primary,
                    title: "Progress",
                    value: "\(Int(viewModel.paymentProgress * 100))%"
                )
            }
        }
    }

    private func progressCard(icon: String, iconColor: Color, title: String, value: String) -> some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            Text(value)
                .font(TNTypography.titleMedium)
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

    // MARK: - Quarterly Payments Section

    private var quarterlyPaymentsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("QUARTERLY PAYMENTS")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                ForEach(viewModel.quarterlyTaxes) { quarter in
                    QuarterlyPaymentRow(quarter: quarter)

                    if quarter.id != viewModel.quarterlyTaxes.last?.id {
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

    // MARK: - Tax Breakdown Section

    private var taxBreakdownSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("TAX BREAKDOWN")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: TNSpacing.md) {
                // Breakdown chart
                HStack(spacing: 2) {
                    ForEach(viewModel.taxBreakdown) { item in
                        Rectangle()
                            .fill(item.color)
                            .frame(height: 12)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(x: item.percentage, anchor: .leading)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Legend
                ForEach(viewModel.taxBreakdown) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)

                        Text(item.category)
                            .font(TNTypography.bodyMedium)
                            .foregroundColor(TNColors.textPrimary)

                        Spacer()

                        Text(item.formattedAmount)
                            .font(TNTypography.titleSmall)
                            .foregroundColor(TNColors.textPrimary)

                        Text("(\(Int(item.percentage * 100))%)")
                            .font(TNTypography.caption)
                            .foregroundColor(TNColors.textSecondary)
                    }
                }
            }
            .padding(TNSpacing.md)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - Income Summary Section

    private var incomeSummarySection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            Text("INCOME SUMMARY")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                incomeSummaryRow(
                    title: "Taxable Income",
                    value: viewModel.formattedYTDTaxableIncome,
                    icon: "dollarsign.circle.fill",
                    iconColor: TNColors.success
                )

                Divider()
                    .padding(.leading, 52)

                incomeSummaryRow(
                    title: "Total Deductions",
                    value: viewModel.formattedYTDDeductions,
                    icon: "minus.circle.fill",
                    iconColor: TNColors.error
                )

                Divider()
                    .padding(.leading, 52)

                incomeSummaryRow(
                    title: "Effective Tax Rate",
                    value: String(format: "%.1f%%", viewModel.ytdTaxableIncome > 0
                        ? (viewModel.totalEstimatedTax as NSDecimalNumber).doubleValue / (viewModel.ytdTaxableIncome as NSDecimalNumber).doubleValue * 100
                        : 0),
                    icon: "percent",
                    iconColor: TNColors.primary
                )
            }
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
            .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        }
    }

    private func incomeSummaryRow(title: String, value: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: TNSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(TNTypography.bodyMedium)
                .foregroundColor(TNColors.textPrimary)

            Spacer()

            Text(value)
                .font(TNTypography.titleMedium)
                .foregroundColor(TNColors.textPrimary)
        }
        .padding(TNSpacing.md)
    }
}

// MARK: - Quarterly Payment Row

struct QuarterlyPaymentRow: View {
    let quarter: QuarterlyTax

    var body: some View {
        HStack(spacing: TNSpacing.md) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(quarter.status.color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: quarter.status.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(quarter.status.color)
            }

            // Quarter Info
            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                HStack(spacing: TNSpacing.xs) {
                    Text(quarter.quarter)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(TNColors.textPrimary)

                    Text(String(quarter.year))
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Text("Due: \(quarter.formattedDueDate)")
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }

            Spacer()

            // Amount and Status
            VStack(alignment: .trailing, spacing: TNSpacing.xxs) {
                Text(quarter.formattedEstimatedAmount)
                    .font(TNTypography.titleMedium)
                    .foregroundColor(TNColors.textPrimary)

                Text(quarter.status.displayName)
                    .font(TNTypography.caption)
                    .foregroundColor(quarter.status.color)
                    .padding(.horizontal, TNSpacing.sm)
                    .padding(.vertical, 2)
                    .background(quarter.status.color.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(TNSpacing.md)
    }
}

// MARK: - Preview

#Preview {
    TaxesView()
        .modelContainer(for: [
            Assignment.self,
            Expense.self,
            MileageTrip.self
        ], inMemory: true)
}
