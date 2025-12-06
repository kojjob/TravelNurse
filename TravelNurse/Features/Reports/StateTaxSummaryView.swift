//
//  StateTaxSummaryView.swift
//  TravelNurse
//
//  Detailed view showing tax breakdown by state
//

import SwiftUI

/// Detailed state-by-state tax breakdown view
struct StateTaxSummaryView: View {
    let stateSummaries: [StateTaxSummary]
    let year: Int

    @State private var selectedState: StateTaxSummary?
    @State private var sortOrder: SortOrder = .income

    enum SortOrder: String, CaseIterable {
        case income = "Income"
        case days = "Days"
        case state = "State"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: TNSpacing.lg) {
                // Summary Header
                summaryHeader

                // Sort Options
                sortPicker

                // Chart Section
                StateBreakdownChart(summaries: sortedSummaries)
                    .frame(height: 200)

                // State List
                stateList
            }
            .padding(.horizontal, TNSpacing.md)
            .padding(.bottom, TNSpacing.xl)
        }
        .background(TNColors.background)
        .navigationTitle("State Breakdown")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedState) { state in
            stateDetailSheet(state)
        }
    }

    // MARK: - Computed Properties

    private var sortedSummaries: [StateTaxSummary] {
        switch sortOrder {
        case .income:
            return stateSummaries.sorted { $0.grossIncome > $1.grossIncome }
        case .days:
            return stateSummaries.sorted { $0.daysWorked > $1.daysWorked }
        case .state:
            return stateSummaries.sorted { $0.state.fullName < $1.state.fullName }
        }
    }

    private var totalGross: Decimal {
        stateSummaries.reduce(0) { $0 + $1.grossIncome }
    }

    private var totalTaxable: Decimal {
        stateSummaries.reduce(0) { $0 + $1.taxableIncome }
    }

    private var noTaxStateIncome: Decimal {
        stateSummaries
            .filter { $0.state.hasNoIncomeTax }
            .reduce(0) { $0 + $1.grossIncome }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: TNSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                    Text("\(year) State Summary")
                        .font(TNTypography.headlineLarge)
                        .foregroundColor(TNColors.textPrimary)

                    Text("\(stateSummaries.count) states worked")
                        .font(TNTypography.caption)
                        .foregroundColor(TNColors.textSecondary)
                }

                Spacer()

                Image(systemName: "map.fill")
                    .font(.system(size: 28))
                    .foregroundColor(TNColors.accent)
            }

            Divider()

            // Quick Stats
            HStack(spacing: TNSpacing.lg) {
                quickStat(
                    title: "No-Tax States",
                    value: "\(noTaxStatesCount)",
                    subtitle: formatCurrency(noTaxStateIncome)
                )

                Divider()
                    .frame(height: 40)

                quickStat(
                    title: "Tax States",
                    value: "\(taxStatesCount)",
                    subtitle: formatCurrency(totalTaxable)
                )
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
    }

    private var noTaxStatesCount: Int {
        stateSummaries.filter { $0.state.hasNoIncomeTax }.count
    }

    private var taxStatesCount: Int {
        stateSummaries.filter { !$0.state.hasNoIncomeTax }.count
    }

    private func quickStat(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: TNSpacing.xxs) {
            Text(title)
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)

            Text(value)
                .font(TNTypography.titleLarge)
                .foregroundColor(TNColors.textPrimary)

            Text(subtitle)
                .font(TNTypography.caption)
                .foregroundColor(TNColors.success)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sort Picker

    private var sortPicker: some View {
        HStack {
            Text("Sort by")
                .font(TNTypography.bodyLarge)
                .foregroundColor(TNColors.textSecondary)

            Spacer()

            Picker("Sort", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
        .padding(.horizontal, TNSpacing.sm)
    }

    // MARK: - State List

    private var stateList: some View {
        VStack(spacing: TNSpacing.sm) {
            ForEach(sortedSummaries) { summary in
                stateCard(summary)
                    .onTapGesture {
                        selectedState = summary
                    }
            }
        }
    }

    private func stateCard(_ summary: StateTaxSummary) -> some View {
        VStack(spacing: TNSpacing.sm) {
            // Header Row
            HStack {
                HStack(spacing: TNSpacing.sm) {
                    Text(summary.state.rawValue)
                        .font(TNTypography.titleMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, TNSpacing.sm)
                        .padding(.vertical, TNSpacing.xs)
                        .background(stateColor(for: summary))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.state.fullName)
                            .font(TNTypography.titleMedium)
                            .foregroundColor(TNColors.textPrimary)

                        if summary.state.hasNoIncomeTax {
                            Text("No State Income Tax")
                                .font(TNTypography.caption)
                                .foregroundColor(TNColors.success)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.textTertiary)
            }

            Divider()

            // Stats Row
            HStack {
                statItem(label: "Days", value: "\(summary.daysWorked)")
                Spacer()
                statItem(label: "Gross", value: summary.formattedGrossIncome)
                Spacer()
                statItem(label: "Taxable", value: summary.formattedTaxableIncome)
                Spacer()
                statItem(label: "Stipends", value: summary.formattedStipends)
            }

            // Income Bar
            incomeBar(summary)
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
    }

    private func stateColor(for summary: StateTaxSummary) -> Color {
        summary.state.hasNoIncomeTax ? TNColors.success : TNColors.primary
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textPrimary)
                .fontWeight(.semibold)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(TNColors.textTertiary)
        }
    }

    private func incomeBar(_ summary: StateTaxSummary) -> some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let taxableRatio = totalGross > 0
                ? CGFloat(truncating: (summary.taxableIncome / totalGross) as NSNumber)
                : 0
            let stipendRatio = totalGross > 0
                ? CGFloat(truncating: (summary.stipends / totalGross) as NSNumber)
                : 0

            HStack(spacing: 2) {
                // Taxable portion
                Rectangle()
                    .fill(TNColors.warning.opacity(0.7))
                    .frame(width: max(taxableRatio * totalWidth, 0))

                // Stipend portion
                Rectangle()
                    .fill(TNColors.success.opacity(0.7))
                    .frame(width: max(stipendRatio * totalWidth, 0))

                Spacer(minLength: 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(height: 8)
        .background(TNColors.border.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - State Detail Sheet

    private func stateDetailSheet(_ state: StateTaxSummary) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // State Header
                    VStack(spacing: TNSpacing.sm) {
                        Text(state.state.rawValue)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(stateColor(for: state))
                            .clipShape(Circle())

                        Text(state.state.fullName)
                            .font(TNTypography.displayMedium)
                            .foregroundColor(TNColors.textPrimary)

                        if state.state.hasNoIncomeTax {
                            Label("No State Income Tax", systemImage: "checkmark.seal.fill")
                                .font(TNTypography.titleMedium)
                                .foregroundColor(TNColors.success)
                        }
                    }
                    .padding(.top, TNSpacing.lg)

                    // Income Details
                    detailCard(title: "Income Summary") {
                        detailRow("Gross Income", state.formattedGrossIncome)
                        detailRow("Taxable Income", state.formattedTaxableIncome)
                        detailRow("Tax-Free Stipends", state.formattedStipends, highlight: true)
                    }

                    // Work Details
                    detailCard(title: "Work Summary") {
                        detailRow("Days Worked", "\(state.daysWorked)")
                        detailRow("Assignments", "\(state.assignments.count)")
                    }

                    // Assignments List
                    if !state.assignments.isEmpty {
                        detailCard(title: "Assignments") {
                            ForEach(state.assignments, id: \.id) { assignment in
                                VStack(alignment: .leading, spacing: TNSpacing.xs) {
                                    Text(assignment.facilityName)
                                        .font(TNTypography.titleMedium)
                                        .foregroundColor(TNColors.textPrimary)

                                    HStack {
                                        Text(assignment.status.displayName)
                                            .font(TNTypography.caption)
                                            .foregroundColor(assignment.status.color)

                                        Spacer()

                                        Text("\(assignment.durationWeeks) weeks")
                                            .font(TNTypography.caption)
                                            .foregroundColor(TNColors.textSecondary)
                                    }
                                }
                                .padding(.vertical, TNSpacing.xs)

                                if assignment != state.assignments.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("State Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedState = nil
                    }
                }
            }
        }
    }

    private func detailCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text(title)
                .font(TNTypography.headlineLarge)
                .foregroundColor(TNColors.textPrimary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
    }

    private func detailRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(TNTypography.bodyLarge)
                .foregroundColor(TNColors.textSecondary)

            Spacer()

            Text(value)
                .font(highlight ? TNTypography.titleMedium : TNTypography.bodyLarge)
                .foregroundColor(highlight ? TNColors.success : TNColors.textPrimary)
        }
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StateTaxSummaryView(
            stateSummaries: [],
            year: 2024
        )
    }
}
