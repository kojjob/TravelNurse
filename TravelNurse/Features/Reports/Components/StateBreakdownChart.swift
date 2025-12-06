//
//  StateBreakdownChart.swift
//  TravelNurse
//
//  Visual chart showing income breakdown by state
//

import SwiftUI

/// Horizontal bar chart showing income distribution by state
struct StateBreakdownChart: View {
    let summaries: [StateTaxSummary]

    @State private var animatedProgress: CGFloat = 0

    private let maxBarsToShow = 5

    var body: some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            // Chart Title
            HStack {
                Text("Income Distribution")
                    .font(TNTypography.headlineSmall)
                    .foregroundColor(TNColors.textSecondary)

                Spacer()

                // Legend
                HStack(spacing: TNSpacing.md) {
                    legendItem(color: TNColors.success, label: "No Tax")
                    legendItem(color: TNColors.primary, label: "Tax State")
                }
            }

            if summaries.isEmpty {
                emptyChartView
            } else {
                chartBars
            }
        }
        .padding(TNSpacing.md)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 2, x: 0, y: 1)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = 1.0
            }
        }
    }

    // MARK: - Computed Properties

    private var totalIncome: Decimal {
        summaries.reduce(0) { $0 + $1.grossIncome }
    }

    private var displayedSummaries: [StateTaxSummary] {
        Array(summaries.prefix(maxBarsToShow))
    }

    private var othersIncome: Decimal {
        guard summaries.count > maxBarsToShow else { return 0 }
        return summaries.dropFirst(maxBarsToShow).reduce(0) { $0 + $1.grossIncome }
    }

    // MARK: - Chart Bars

    private var chartBars: some View {
        VStack(spacing: TNSpacing.xs) {
            ForEach(displayedSummaries) { summary in
                chartBar(for: summary)
            }

            // Others row if needed
            if othersIncome > 0 {
                othersBar
            }
        }
    }

    private func chartBar(for summary: StateTaxSummary) -> some View {
        let percentage = totalIncome > 0
            ? CGFloat(truncating: (summary.grossIncome / totalIncome) as NSNumber)
            : 0
        let barColor = summary.state.hasNoIncomeTax ? TNColors.success : TNColors.primary

        return HStack(spacing: TNSpacing.sm) {
            // State Code
            Text(summary.state.rawValue)
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .frame(width: 28, alignment: .leading)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.border.opacity(0.3))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * percentage * animatedProgress)
                }
            }
            .frame(height: 20)

            // Percentage
            Text(formatPercentage(percentage))
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var othersBar: some View {
        let percentage = totalIncome > 0
            ? CGFloat(truncating: (othersIncome / totalIncome) as NSNumber)
            : 0
        let othersCount = summaries.count - maxBarsToShow

        return HStack(spacing: TNSpacing.sm) {
            // Label
            Text("+\(othersCount)")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .frame(width: 28, alignment: .leading)

            // Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.border.opacity(0.3))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(TNColors.textTertiary)
                        .frame(width: geometry.size.width * percentage * animatedProgress)
                }
            }
            .frame(height: 20)

            // Percentage
            Text(formatPercentage(percentage))
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Helper Views

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(TNColors.textTertiary)
        }
    }

    private var emptyChartView: some View {
        VStack(spacing: TNSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(TNColors.textTertiary)

            Text("No income data")
                .font(TNTypography.caption)
                .foregroundColor(TNColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Helpers

    private func formatPercentage(_ value: CGFloat) -> String {
        let percentage = value * 100
        if percentage < 1 && percentage > 0 {
            return "<1%"
        }
        return "\(Int(percentage))%"
    }
}

// MARK: - Pie Chart Alternative

/// Circular chart showing state income distribution
struct StatePieChart: View {
    let summaries: [StateTaxSummary]

    @State private var animatedProgress: CGFloat = 0

    private var totalIncome: Decimal {
        summaries.reduce(0) { $0 + $1.grossIncome }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Pie segments
                pieSegments(size: size, center: center)

                // Center circle with total
                Circle()
                    .fill(TNColors.surface)
                    .frame(width: size * 0.5, height: size * 0.5)
                    .overlay {
                        VStack(spacing: 2) {
                            Text("\(summaries.count)")
                                .font(TNTypography.displaySmall)
                                .foregroundColor(TNColors.textPrimary)
                            Text("States")
                                .font(TNTypography.caption)
                                .foregroundColor(TNColors.textSecondary)
                        }
                    }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = 1.0
            }
        }
    }

    @ViewBuilder
    private func pieSegments(size: CGFloat, center: CGPoint) -> some View {
        Canvas { context, canvasSize in
            var startAngle = Angle.degrees(-90)

            for summary in summaries {
                let percentage = totalIncome > 0
                    ? Double(truncating: (summary.grossIncome / totalIncome) as NSNumber)
                    : 0
                let sweepAngle = Angle.degrees(360 * percentage * Double(animatedProgress))
                let endAngle = startAngle + sweepAngle

                let path = Path { p in
                    p.move(to: center)
                    p.addArc(
                        center: center,
                        radius: size / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    p.closeSubpath()
                }

                let color = summary.state.hasNoIncomeTax ? TNColors.success : TNColors.primary
                context.fill(path, with: .color(color.opacity(0.8 - Double(summaries.firstIndex(of: summary)!) * 0.1)))

                startAngle = endAngle
            }
        }
    }
}

// MARK: - Preview

#Preview("Bar Chart") {
    StateBreakdownChart(summaries: [])
        .frame(height: 200)
        .padding()
}

#Preview("Pie Chart") {
    StatePieChart(summaries: [])
        .frame(width: 200, height: 200)
        .padding()
}
