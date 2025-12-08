//
//  OnboardingCompleteView.swift
//  TravelNurse
//
//  Enhanced celebration screen with detailed summary
//

import SwiftUI

/// Completion celebration screen - final step before entering the app
struct OnboardingCompleteView: View {

    let userName: String
    let selectedGoalsCount: Int
    let summary: OnboardingSummary?
    let onGetStarted: () -> Void

    // Animation states
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var detailsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiTriggered = false

    // Backward compatibility initializer
    init(userName: String, selectedGoalsCount: Int, onGetStarted: @escaping () -> Void) {
        self.userName = userName
        self.selectedGoalsCount = selectedGoalsCount
        self.summary = nil
        self.onGetStarted = onGetStarted
    }

    // Enhanced initializer with summary
    init(userName: String, selectedGoalsCount: Int, summary: OnboardingSummary, onGetStarted: @escaping () -> Void) {
        self.userName = userName
        self.selectedGoalsCount = selectedGoalsCount
        self.summary = summary
        self.onGetStarted = onGetStarted
    }

    var body: some View {
        ZStack {
            // Gradient background
            backgroundGradient

            // Confetti overlay (subtle)
            if confettiTriggered {
                ConfettiView()
                    .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // Success checkmark
                    successCheckmark
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)

                    Spacer()
                        .frame(height: 32)

                    // Congratulations text
                    congratulationsSection
                        .opacity(textOpacity)

                    Spacer()
                        .frame(height: 32)

                    // Profile Summary
                    if let summary = summary {
                        profileSummary(summary)
                            .opacity(detailsOpacity)

                        Spacer()
                            .frame(height: 24)
                    }

                    // Quick Stats cards
                    quickStatsSection
                        .opacity(detailsOpacity)

                    Spacer()
                        .frame(height: 40)

                    // Get Started button
                    getStartedButton
                        .opacity(buttonOpacity)

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            animateEntrance()
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "E8F5E9"),  // Light green
                Color(hex: "F1F8E9"),  // Lighter green
                Color(hex: "FFFDE7")   // Soft yellow
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Success Checkmark

    private var successCheckmark: some View {
        ZStack {
            // Animated rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [TNColors.secondary.opacity(0.3), TNColors.success.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(120 + index * 30), height: CGFloat(120 + index * 30))
                    .opacity(checkmarkOpacity * (1 - Double(index) * 0.3))
            }

            // Main circle
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [TNColors.secondary, TNColors.success],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 100, height: 100)

            // Inner fill
            Circle()
                .fill(
                    LinearGradient(
                        colors: [TNColors.secondary.opacity(0.2), TNColors.success.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(TNColors.secondary)
        }
    }

    // MARK: - Congratulations Section

    private var congratulationsSection: some View {
        VStack(spacing: 12) {
            Text("You're All Set!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)

            Text("Welcome\(userName.isEmpty ? "" : ", \(userName)")!")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(TNColors.textPrimaryLight)

            Text("Your TravelNurse companion is ready to help you maximize your earnings and stay tax-compliant.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(TNColors.textSecondaryLight)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Profile Summary

    private func profileSummary(_ summary: OnboardingSummary) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Setup")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(TNColors.textSecondaryLight)
                    .textCase(.uppercase)
                    .tracking(1)

                Spacer()
            }

            VStack(spacing: 12) {
                // Profile Row
                if !summary.fullName.isEmpty {
                    SummaryRow(
                        icon: "person.fill",
                        color: TNColors.primary,
                        title: "Profile",
                        value: summary.fullName,
                        subtitle: summary.specialty
                    )
                }

                // Tax Home Row
                if let taxHome = summary.taxHomeLocation {
                    SummaryRow(
                        icon: "house.fill",
                        color: TNColors.success,
                        title: "Tax Home",
                        value: taxHome,
                        subtitle: nil
                    )
                } else {
                    SummaryRow(
                        icon: "house.fill",
                        color: TNColors.textTertiaryLight,
                        title: "Tax Home",
                        value: "Not set",
                        subtitle: "Set up in Settings"
                    )
                }

                // Goals Row
                SummaryRow(
                    icon: "target",
                    color: TNColors.warning,
                    title: "Goals",
                    value: "\(summary.goalsCount) selected",
                    subtitle: nil
                )
            }
            .padding(20)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                icon: "shield.checkered",
                title: "Secure",
                subtitle: "Data Storage",
                color: TNColors.secondary
            )

            QuickStatCard(
                icon: "bell.badge.fill",
                title: "Smart",
                subtitle: "Reminders",
                color: TNColors.primary
            )

            QuickStatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Track",
                subtitle: "Earnings",
                color: TNColors.success
            )
        }
    }

    // MARK: - Get Started Button

    private var getStartedButton: some View {
        Button(action: onGetStarted) {
            HStack(spacing: 12) {
                Text("Let's Go!")
                    .font(.system(size: 18, weight: .bold))

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: [TNColors.secondary, TNColors.success],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: TNColors.secondary.opacity(0.4), radius: 12, y: 6)
        }
    }

    // MARK: - Animation

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            checkmarkScale = 1
            checkmarkOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            textOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            detailsOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
            buttonOpacity = 1
        }

        // Trigger confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiTriggered = true
        }
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TNColors.textTertiaryLight)
                    .textCase(.uppercase)

                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TNColors.textPrimaryLight)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(TNColors.textSecondaryLight)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(color == TNColors.textTertiaryLight ? TNColors.textTertiaryLight : TNColors.success)
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(TNColors.textPrimaryLight)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Summary Card (Legacy)

struct SummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(TNColors.textSecondaryLight)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Simple Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: particle.isCircle ? particle.size : 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.isCircle ? particle.size : particle.size * 2)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [
            TNColors.secondary,
            TNColors.primary,
            TNColors.success,
            Color(hex: "F59E0B"),
            Color(hex: "8B5CF6"),
            Color(hex: "EF4444")
        ]

        particles = (0..<50).map { _ in
            ConfettiParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                isCircle: Bool.random()
            )
        }
    }

    private func animateParticles() {
        for index in particles.indices {
            let delay = Double.random(in: 0...0.8)
            let duration = Double.random(in: 2.0...3.5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[index].position.y += 1000
                particles[index].position.x += CGFloat.random(in: -100...100)
                particles[index].rotation += Double.random(in: 180...720)
                particles[index].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var rotation: Double = 0
    var isCircle: Bool = true
}

// MARK: - Preview

#Preview {
    OnboardingCompleteView(
        userName: "Sarah",
        selectedGoalsCount: 4,
        summary: OnboardingSummary(
            fullName: "Sarah Johnson",
            specialty: "ICU",
            taxHomeLocation: "Houston, TX",
            goalsCount: 4
        ),
        onGetStarted: {}
    )
}
