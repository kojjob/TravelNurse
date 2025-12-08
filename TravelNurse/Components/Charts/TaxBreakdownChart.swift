//
//  TaxBreakdownChart.swift
//  TravelNurse
//
//  Interactive donut chart for visualizing tax breakdown
//

import SwiftUI

/// Data model for a chart segment
struct ChartSegment: Identifiable {
    let id = UUID()
    let label: String
    let value: Decimal
    let color: Color
    let percentage: Double

    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$0"
    }

    var formattedPercentage: String {
        String(format: "%.1f%%", percentage * 100)
    }
}

/// Animated donut chart for tax breakdown visualization
struct TaxBreakdownChart: View {

    let segments: [ChartSegment]
    let totalAmount: Decimal
    let centerTitle: String
    let centerSubtitle: String

    @State private var selectedSegment: ChartSegment?
    @State private var animationProgress: Double = 0

    private let lineWidth: CGFloat = 28
    private let gapAngle: Double = 2 // Degrees between segments

    init(
        segments: [ChartSegment],
        totalAmount: Decimal,
        centerTitle: String = "Total Tax",
        centerSubtitle: String = ""
    ) {
        self.segments = segments
        self.totalAmount = totalAmount
        self.centerTitle = centerTitle
        self.centerSubtitle = centerSubtitle
    }

    var body: some View {
        VStack(spacing: TNSpacing.xl) {
            // Donut Chart
            ZStack {
                // Background ring
                Circle()
                    .stroke(TNColors.border.opacity(0.3), lineWidth: lineWidth)

                // Segment arcs
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    SegmentArc(
                        segment: segment,
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        lineWidth: lineWidth,
                        isSelected: selectedSegment?.id == segment.id,
                        animationProgress: animationProgress
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedSegment?.id == segment.id {
                                selectedSegment = nil
                            } else {
                                selectedSegment = segment
                            }
                        }
                    }
                }

                // Center content
                VStack(spacing: TNSpacing.xxs) {
                    if let selected = selectedSegment {
                        // Show selected segment details
                        Text(selected.label)
                            .font(TNTypography.labelSmall)
                            .foregroundStyle(TNColors.textSecondary)

                        Text(selected.formattedValue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(selected.color)

                        Text(selected.formattedPercentage)
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                    } else {
                        // Show total
                        Text(centerTitle)
                            .font(TNTypography.labelSmall)
                            .foregroundStyle(TNColors.textSecondary)

                        Text(formattedTotal)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(TNColors.textPrimary)

                        if !centerSubtitle.isEmpty {
                            Text(centerSubtitle)
                                .font(TNTypography.caption)
                                .foregroundStyle(TNColors.textSecondary)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: selectedSegment?.id)
            }
            .frame(width: 200, height: 200)
            .padding(TNSpacing.md)

            // Legend
            legendView
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(spacing: TNSpacing.sm) {
            ForEach(segments) { segment in
                HStack(spacing: TNSpacing.sm) {
                    // Color indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(segment.color)
                        .frame(width: 16, height: 16)
                        .overlay {
                            if selectedSegment?.id == segment.id {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(TNColors.textPrimary, lineWidth: 2)
                            }
                        }

                    // Label
                    Text(segment.label)
                        .font(TNTypography.bodySmall)
                        .foregroundStyle(TNColors.textPrimary)

                    Spacer()

                    // Value
                    Text(segment.formattedValue)
                        .font(TNTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(TNColors.textPrimary)

                    // Percentage badge
                    Text(segment.formattedPercentage)
                        .font(TNTypography.caption)
                        .foregroundStyle(segment.color)
                        .padding(.horizontal, TNSpacing.xs)
                        .padding(.vertical, 2)
                        .background(segment.color.opacity(0.1))
                        .clipShape(Capsule())
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedSegment?.id == segment.id {
                            selectedSegment = nil
                        } else {
                            selectedSegment = segment
                        }
                    }
                }
                .opacity(selectedSegment == nil || selectedSegment?.id == segment.id ? 1 : 0.5)
            }
        }
        .padding(.horizontal, TNSpacing.sm)
    }

    // MARK: - Helpers

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalAmount as NSNumber) ?? "$0"
    }

    private func startAngle(for index: Int) -> Double {
        var angle: Double = -90 // Start from top
        for i in 0..<index {
            angle += segments[i].percentage * 360 + gapAngle
        }
        return angle
    }

    private func endAngle(for index: Int) -> Double {
        startAngle(for: index) + segments[index].percentage * 360
    }
}

// MARK: - Segment Arc

struct SegmentArc: View {
    let segment: ChartSegment
    let startAngle: Double
    let endAngle: Double
    let lineWidth: CGFloat
    let isSelected: Bool
    let animationProgress: Double

    var body: some View {
        Circle()
            .trim(from: trimStart, to: trimEnd * animationProgress)
            .stroke(
                segment.color,
                style: StrokeStyle(
                    lineWidth: isSelected ? lineWidth + 6 : lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(startAngle))
            .shadow(
                color: isSelected ? segment.color.opacity(0.4) : .clear,
                radius: isSelected ? 8 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var trimStart: CGFloat {
        0
    }

    private var trimEnd: CGFloat {
        CGFloat((endAngle - startAngle) / 360)
    }
}

// MARK: - Compact Version

/// A smaller, more compact version of the tax breakdown chart
struct CompactTaxBreakdownChart: View {

    let segments: [ChartSegment]
    let totalAmount: Decimal

    private let lineWidth: CGFloat = 20

    var body: some View {
        HStack(spacing: TNSpacing.lg) {
            // Mini donut
            ZStack {
                Circle()
                    .stroke(TNColors.border.opacity(0.3), lineWidth: lineWidth)

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    Circle()
                        .trim(from: trimStart(for: index), to: trimEnd(for: index))
                        .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                Text(formattedTotal)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(TNColors.textPrimary)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: 100, height: 100)

            // Vertical legend
            VStack(alignment: .leading, spacing: TNSpacing.xs) {
                ForEach(segments) { segment in
                    HStack(spacing: TNSpacing.xs) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)

                        Text(segment.label)
                            .font(TNTypography.caption)
                            .foregroundStyle(TNColors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        Text(segment.formattedPercentage)
                            .font(TNTypography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(segment.color)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: totalAmount as NSNumber) ?? "$0"
    }

    private func trimStart(for index: Int) -> CGFloat {
        var start: CGFloat = 0
        for i in 0..<index {
            start += CGFloat(segments[i].percentage)
        }
        return start
    }

    private func trimEnd(for index: Int) -> CGFloat {
        trimStart(for: index) + CGFloat(segments[index].percentage)
    }
}

// MARK: - Preview

#Preview("Tax Breakdown Chart") {
    let segments = [
        ChartSegment(label: "Federal", value: 12500, color: TNColors.primary, percentage: 0.45),
        ChartSegment(label: "Social Security", value: 8200, color: TNColors.accent, percentage: 0.30),
        ChartSegment(label: "Medicare", value: 4100, color: TNColors.secondary, percentage: 0.15),
        ChartSegment(label: "State", value: 2700, color: TNColors.warning, percentage: 0.10)
    ]

    VStack(spacing: 40) {
        TaxBreakdownChart(
            segments: segments,
            totalAmount: 27500,
            centerTitle: "Total Tax",
            centerSubtitle: "2024 Estimate"
        )

        Divider()

        CompactTaxBreakdownChart(
            segments: segments,
            totalAmount: 27500
        )
        .padding()
    }
    .padding()
}
