//
//  ComplianceScoreRing.swift
//  TravelNurse
//
//  Circular progress ring showing compliance score
//

import SwiftUI

/// Circular progress ring that displays compliance score with animated fill
struct ComplianceScoreRing: View {

    // MARK: - Properties

    /// Current compliance score (0-100)
    let score: Int

    /// Compliance level for color coding
    let level: ComplianceLevel

    /// Ring size (diameter)
    var size: CGFloat = 180

    /// Ring stroke width
    var strokeWidth: CGFloat = 16

    /// Whether to show the score label
    var showLabel: Bool = true

    /// Animation state
    @State private var animatedProgress: Double = 0

    // MARK: - Computed Properties

    /// Progress value (0.0 to 1.0)
    private var progress: Double {
        Double(score) / 100.0
    }

    /// Ring color based on compliance level
    private var ringColor: Color {
        level.color
    }

    /// Background ring color
    private var backgroundRingColor: Color {
        level.color.opacity(0.2)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    backgroundRingColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animatedProgress)

            // Center content
            if showLabel {
                centerContent
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: score) { _, _ in
            animatedProgress = progress
        }
    }

    // MARK: - Subviews

    /// Gradient for the progress ring
    private var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                ringColor.opacity(0.8),
                ringColor
            ]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedProgress)
        )
    }

    /// Center content with score and label
    private var centerContent: some View {
        VStack(spacing: 4) {
            // Score number
            Text("\(score)")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(TNColors.textPrimary)
                .contentTransition(.numericText())

            // Label
            Text("Score")
                .font(.system(size: size * 0.1, weight: .medium))
                .foregroundStyle(TNColors.textSecondary)

            // Level badge
            HStack(spacing: 4) {
                Image(systemName: level.iconName)
                    .font(.system(size: size * 0.07))
                Text(level.displayName)
                    .font(.system(size: size * 0.08, weight: .semibold))
            }
            .foregroundStyle(ringColor)
        }
    }
}

// MARK: - Compact Score Ring

/// Smaller version of the compliance score ring for cards/widgets
struct CompactScoreRing: View {

    let score: Int
    let level: ComplianceLevel
    var size: CGFloat = 60

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        Double(score) / 100.0
    }

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(
                    level.color.opacity(0.2),
                    lineWidth: 6
                )

            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    level.color,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animatedProgress)

            // Score
            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(TNColors.textPrimary)
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: score) { _, _ in
            animatedProgress = progress
        }
    }
}

// MARK: - Score Badge

/// Badge showing compliance score with level indicator
struct ComplianceScoreBadge: View {

    let score: Int
    let level: ComplianceLevel

    var body: some View {
        HStack(spacing: 8) {
            // Score circle
            ZStack {
                Circle()
                    .fill(level.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text("\(score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(level.color)
            }

            // Level info
            VStack(alignment: .leading, spacing: 2) {
                Text("Compliance Score")
                    .font(.caption)
                    .foregroundStyle(TNColors.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: level.iconName)
                        .font(.caption)
                    Text(level.displayName)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(level.color)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(TNColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(level.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews

#Preview("Compliance Score Ring") {
    VStack(spacing: 32) {
        // Excellent
        ComplianceScoreRing(score: 95, level: .excellent)

        // Good
        ComplianceScoreRing(score: 75, level: .good, size: 140)

        // At Risk
        ComplianceScoreRing(score: 55, level: .atRisk, size: 120)

        // Non-Compliant
        ComplianceScoreRing(score: 35, level: .nonCompliant, size: 100)
    }
    .padding()
}

#Preview("Compact Score Ring") {
    HStack(spacing: 24) {
        CompactScoreRing(score: 92, level: .excellent)
        CompactScoreRing(score: 78, level: .good)
        CompactScoreRing(score: 52, level: .atRisk)
        CompactScoreRing(score: 30, level: .nonCompliant)
    }
    .padding()
}

#Preview("Score Badge") {
    VStack(spacing: 16) {
        ComplianceScoreBadge(score: 95, level: .excellent)
        ComplianceScoreBadge(score: 75, level: .good)
        ComplianceScoreBadge(score: 55, level: .atRisk)
        ComplianceScoreBadge(score: 35, level: .nonCompliant)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
