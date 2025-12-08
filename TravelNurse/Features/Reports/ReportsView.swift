//
//  ReportsView.swift
//  TravelNurse
//
//  Tax reports view with annual summaries and state breakdowns
//  Bold, proportional design with visual hierarchy
//

import SwiftUI
import SwiftData
import UIKit

/// Main reports view showing annual tax summaries and state breakdowns
struct ReportsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ReportsViewModel()
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showingExportSheet = false

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 4)...currentYear).reversed()
    }

    /// Share a file via the system share sheet
    @MainActor
    private func shareFile(url: URL) async {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        // For iPad - present as popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                        y: rootViewController.view.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        rootViewController.present(activityVC, animated: true)
        #endif
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.xxl) {
                    // Year Selector - Prominent pill design
                    yearSelectorSection

                    // Hero Income Card - Bold gradient design
                    heroIncomeSection

                    // Metrics Grid - Proportional 2x2 layout
                    metricsGridSection

                    // State Earnings - Enhanced breakdown
                    stateEarningsSection

                    // Export Actions - Bold action cards
                    exportActionsSection
                }
                .padding(.horizontal, TNSpacing.lg)
                .padding(.bottom, TNSpacing.xxxl)
            }
            .background(TNColors.background)
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(TNColors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(TNColors.primary)
                    }
                }
            }
            .onAppear {
                viewModel.loadData(for: selectedYear)
            }
            .onChange(of: selectedYear) { _, newYear in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.loadData(for: newYear)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOptionsSheet(viewModel: viewModel)
                    .presentationDetents([.large])
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
                            .font(TNTypography.titleMedium)
                            .fontWeight(selectedYear == year ? .bold : .medium)
                            .foregroundStyle(selectedYear == year ? .white : TNColors.textSecondary)
                            .padding(.horizontal, TNSpacing.xl)
                            .padding(.vertical, TNSpacing.md)
                            .background {
                                if selectedYear == year {
                                    Capsule()
                                        .fill(TNColors.primaryGradient)
                                        .shadow(color: TNColors.primary.opacity(0.3), radius: 8, y: 4)
                                } else {
                                    Capsule()
                                        .fill(TNColors.surface)
                                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, TNSpacing.xs)
        }
    }

    // MARK: - Hero Income Section

    private var heroIncomeSection: some View {
        VStack(spacing: TNSpacing.lg) {
            // Main income card with gradient
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: TNSpacing.radiusXL)
                    .fill(TNColors.successGradient)
                    .shadow(color: TNColors.success.opacity(0.3), radius: 16, y: 8)

                // Pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        path.move(to: CGPoint(x: width * 0.6, y: 0))
                        path.addCurve(
                            to: CGPoint(x: width, y: height * 0.6),
                            control1: CGPoint(x: width * 0.8, y: height * 0.2),
                            control2: CGPoint(x: width, y: height * 0.4)
                        )
                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: width * 0.8, y: height))
                        path.addCurve(
                            to: CGPoint(x: width * 0.6, y: 0),
                            control1: CGPoint(x: width * 0.7, y: height * 0.5),
                            control2: CGPoint(x: width * 0.65, y: height * 0.1)
                        )
                    }
                    .fill(Color.white.opacity(0.1))
                }

                // Content
                VStack(spacing: TNSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                            Text("TOTAL INCOME")
                                .font(TNTypography.overline)
                                .fontWeight(.bold)
                                .tracking(TNTypography.extraWideTracking)
                                .foregroundStyle(.white.opacity(0.8))

                            Text(String(selectedYear))
                                .font(TNTypography.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        Spacer()

                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    HStack(alignment: .firstTextBaseline) {
                        Text(viewModel.formattedTotalIncome)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()
                    }

                    HStack {
                        Label {
                            Text("Gross earnings")
                                .font(TNTypography.bodySmall)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(.white.opacity(0.9))

                        Spacer()

                        // Trend indicator
                        HStack(spacing: TNSpacing.xxs) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                            Text("YTD")
                                .font(TNTypography.labelSmall)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, TNSpacing.sm)
                        .padding(.vertical, TNSpacing.xs)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }
                .padding(TNSpacing.xl)
            }
            .frame(height: 200)
        }
    }

    // MARK: - Metrics Grid Section

    private var metricsGridSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Financial Overview")
                .font(TNTypography.headlineMedium)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: TNSpacing.md),
                GridItem(.flexible(), spacing: TNSpacing.md)
            ], spacing: TNSpacing.md) {

                // Expenses Card
                BoldMetricCard(
                    title: "Expenses",
                    value: viewModel.formattedTotalExpenses,
                    subtitle: "Tax Deductible",
                    icon: "creditcard.fill",
                    iconColor: TNColors.primary,
                    backgroundColor: TNColors.primary.opacity(0.1)
                )

                // Mileage Card
                BoldMetricCard(
                    title: "Mileage",
                    value: viewModel.formattedMileageDeduction,
                    subtitle: String(format: "%.0f mi", viewModel.totalMiles),
                    icon: "car.fill",
                    iconColor: TNColors.accent,
                    backgroundColor: TNColors.accent.opacity(0.1)
                )

                // Net Income Card
                BoldMetricCard(
                    title: "Net Income",
                    value: viewModel.formattedNetIncome,
                    subtitle: "After Deductions",
                    icon: "banknote.fill",
                    iconColor: TNColors.success,
                    backgroundColor: TNColors.success.opacity(0.1)
                )

                // Tax Estimate Card
                BoldMetricCard(
                    title: "Est. Tax",
                    value: viewModel.formattedEstimatedTax,
                    subtitle: "Federal + State",
                    icon: "building.columns.fill",
                    iconColor: TNColors.warning,
                    backgroundColor: TNColors.warning.opacity(0.1)
                )
            }
        }
    }

    // MARK: - State Earnings Section

    private var stateEarningsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            HStack {
                Text("State Breakdown")
                    .font(TNTypography.headlineMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(TNColors.textPrimary)

                Spacer()

                if !viewModel.stateBreakdowns.isEmpty {
                    Text("\(viewModel.stateBreakdowns.count) states")
                        .font(TNTypography.labelMedium)
                        .foregroundStyle(TNColors.textSecondary)
                }
            }

            if viewModel.stateBreakdowns.isEmpty {
                emptyStateBreakdown
            } else {
                VStack(spacing: TNSpacing.sm) {
                    ForEach(viewModel.stateBreakdowns, id: \.state) { breakdown in
                        BoldStateRow(
                            breakdown: breakdown,
                            maxEarnings: viewModel.stateBreakdowns.map(\.earnings).max() ?? 1
                        )
                    }
                }
                .padding(TNSpacing.lg)
                .background(TNColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            }
        }
    }

    private var emptyStateBreakdown: some View {
        VStack(spacing: TNSpacing.lg) {
            ZStack {
                Circle()
                    .fill(TNColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "map.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(TNColors.primary)
            }

            VStack(spacing: TNSpacing.xs) {
                Text("No State Data Yet")
                    .font(TNTypography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(TNColors.textPrimary)

                Text("Complete assignments to see your\nearnings by state")
                    .font(TNTypography.bodyMedium)
                    .foregroundStyle(TNColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.xxxl)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Export Actions Section

    private var exportActionsSection: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            Text("Quick Actions")
                .font(TNTypography.headlineMedium)
                .fontWeight(.bold)
                .foregroundStyle(TNColors.textPrimary)

            HStack(spacing: TNSpacing.md) {
                BoldActionButton(
                    title: "CSV",
                    icon: "tablecells.fill",
                    color: TNColors.primary,
                    action: {
                        Task {
                            if let url = await viewModel.exportToCSV(year: selectedYear) {
                                await shareFile(url: url)
                            }
                        }
                    }
                )

                BoldActionButton(
                    title: "PDF",
                    icon: "doc.richtext.fill",
                    color: TNColors.accent,
                    action: {
                        Task {
                            if let url = await viewModel.generatePDFReport(year: selectedYear) {
                                await shareFile(url: url)
                            }
                        }
                    }
                )

                BoldActionButton(
                    title: "Share",
                    icon: "square.and.arrow.up.fill",
                    color: TNColors.success,
                    action: {
                        Task {
                            if let url = await viewModel.shareReport(year: selectedYear) {
                                await shareFile(url: url)
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Bold Metric Card

struct BoldMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.md) {
            // Icon with colored background
            ZStack {
                RoundedRectangle(cornerRadius: TNSpacing.radiusSM)
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                Text(value)
                    .font(TNTypography.moneyMedium)
                    .foregroundStyle(TNColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(TNTypography.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(TNColors.textPrimary)

                Text(subtitle)
                    .font(TNTypography.caption)
                    .foregroundStyle(TNColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Bold State Row

struct BoldStateRow: View {
    let breakdown: StateBreakdown
    let maxEarnings: Decimal

    private var progress: CGFloat {
        guard maxEarnings > 0 else { return 0 }
        return CGFloat(truncating: (breakdown.earnings / maxEarnings) as NSNumber)
    }

    var body: some View {
        VStack(spacing: TNSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TNSpacing.xxs) {
                    Text(breakdown.state.displayName)
                        .font(TNTypography.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(TNColors.textPrimary)

                    HStack(spacing: TNSpacing.sm) {
                        Label("\(breakdown.weeksWorked)w", systemImage: "calendar")
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)

                        if breakdown.hasStateTax {
                            Label("Tax", systemImage: "exclamationmark.triangle.fill")
                                .font(TNTypography.caption)
                                .foregroundStyle(TNColors.warning)
                        } else {
                            Label("No tax", systemImage: "checkmark.circle.fill")
                                .font(TNTypography.caption)
                                .foregroundStyle(TNColors.success)
                        }
                    }
                }

                Spacer()

                Text(breakdown.formattedEarnings)
                    .font(TNTypography.moneySmall)
                    .foregroundStyle(TNColors.success)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [TNColors.primary, TNColors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, TNSpacing.xs)
    }
}

// MARK: - Bold Action Button

struct BoldActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: TNSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(TNTypography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(TNColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TNSpacing.lg)
            .background(TNColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusLG))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        ReportsView()
            .modelContainer(for: [
                Assignment.self,
                Expense.self,
                MileageTrip.self
            ], inMemory: true)
    }
}
