//
//  OnboardingCompleteView.swift
//  TravelNurse
//
//  Celebration screen shown after onboarding completion
//

import SwiftUI

/// Completion celebration screen - final step before entering the app
struct OnboardingCompleteView: View {

    let userName: String
    let selectedGoalsCount: Int
    let onGetStarted: () -> Void

    // Animation states
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var confettiTriggered = false

    var body: some View {
        ZStack {
            // Gradient background
            backgroundGradient

            // Confetti overlay (subtle)
            if confettiTriggered {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()

                // Success checkmark
                successCheckmark
                    .scaleEffect(checkmarkScale)
                    .opacity(checkmarkOpacity)

                Spacer()
                    .frame(height: 40)

                // Congratulations text
                congratulationsSection
                    .opacity(textOpacity)

                Spacer()
                    .frame(height: 24)

                // Summary cards
                summarySection
                    .opacity(textOpacity)

                Spacer()

                // Get Started button
                getStartedButton
                    .opacity(buttonOpacity)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
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
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [TNColors.secondary, TNColors.success],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 120, height: 120)

            // Inner fill
            Circle()
                .fill(
                    LinearGradient(
                        colors: [TNColors.secondary.opacity(0.2), TNColors.success.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(TNColors.secondary)
        }
    }

    // MARK: - Congratulations Section

    private var congratulationsSection: some View {
        VStack(spacing: 12) {
            Text("You're All Set!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)

            Text("Welcome\(userName.isEmpty ? "" : ", \(userName)")! Your TravelNurse companion is ready to help you manage your finances.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(TNColors.textSecondaryLight)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        HStack(spacing: 16) {
            SummaryCard(
                icon: "target",
                value: "\(selectedGoalsCount)",
                label: "Goals Set",
                color: TNColors.primary
            )

            SummaryCard(
                icon: "shield.checkered",
                value: "Secure",
                label: "Your Data",
                color: TNColors.secondary
            )

            SummaryCard(
                icon: "sparkles",
                value: "Ready",
                label: "To Track",
                color: TNColors.warning
            )
        }
    }

    // MARK: - Get Started Button

    private var getStartedButton: some View {
        Button(action: onGetStarted) {
            HStack(spacing: 8) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [TNColors.secondary, TNColors.success],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: TNColors.secondary.opacity(0.3), radius: 8, y: 4)
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

        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            buttonOpacity = 1
        }

        // Trigger confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiTriggered = true
        }
    }
}

// MARK: - Summary Card

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
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
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
            Color(hex: "0066FF"),
            Color(hex: "F59E0B"),
            Color(hex: "8B5CF6"),
            Color(hex: "EF4444")
        ]

        particles = (0..<30).map { _ in
            ConfettiParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        for index in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...2.5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[index].position.y += 800
                particles[index].position.x += CGFloat.random(in: -50...50)
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
}

// MARK: - Preview

#Preview {
    OnboardingCompleteView(
        userName: "Sarah",
        selectedGoalsCount: 4,
        onGetStarted: {}
    )
}
