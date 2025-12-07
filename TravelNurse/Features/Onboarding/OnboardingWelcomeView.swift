//
//  OnboardingWelcomeView.swift
//  TravelNurse
//
//  Welcome screen for onboarding flow with warm gradient design
//

import SwiftUI

/// Welcome screen - first step of onboarding
struct OnboardingWelcomeView: View {

    let onContinue: () -> Void
    let onContinueAnonymous: () -> Void
    let onAlreadyMember: () -> Void

    // Animation states
    @State private var illustrationScale: CGFloat = 0.8
    @State private var illustrationOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0

    var body: some View {
        ZStack {
            // Warm gradient background (peach/cream like the design)
            backgroundGradient

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Welcome text
                welcomeHeader
                    .opacity(textOpacity)

                Spacer()
                    .frame(height: 40)

                // Illustration
                illustrationView
                    .scaleEffect(illustrationScale)
                    .opacity(illustrationOpacity)

                Spacer()

                // Buttons
                actionButtons
                    .opacity(buttonsOpacity)

                // Already a member link
                alreadyMemberLink
                    .opacity(buttonsOpacity)

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
                Color(hex: "E8F4FF"),  // Light blue
                Color(hex: "CCE7FF"),  // Soft blue
                Color(hex: "B3DBFF")   // Gentle blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        VStack(spacing: 8) {
            Text("Welcome to TravelNurse")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "FF8C42"))  // Warm orange

            Text("Let's get your\nfinances in order")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Illustration

    private var illustrationView: some View {
        // App Logo from assets
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 200, height: 200)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Primary Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(TNColors.textPrimaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }

            // Secondary Anonymous Button
            Button(action: onContinueAnonymous) {
                Text("Continue Anonymous")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(TNColors.textPrimaryLight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(TNColors.textPrimaryLight.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Already Member Link

    private var alreadyMemberLink: some View {
        Button(action: onAlreadyMember) {
            Text("ALREADY A MEMBER?")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1)
                .foregroundColor(TNColors.textSecondaryLight)
        }
        .padding(.top, 24)
    }

    // MARK: - Animation

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            textOpacity = 1
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
            illustrationScale = 1
            illustrationOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            buttonsOpacity = 1
        }
    }
}

// MARK: - Travel Nurse Illustration

struct TravelNurseIllustration: View {
    var body: some View {
        ZStack {
            // Suitcase
            SuitcaseShape()
                .fill(TNColors.accent)
                .frame(width: 100, height: 80)
                .offset(y: 30)

            // Suitcase details
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "7C3AED"))
                .frame(width: 80, height: 8)
                .offset(y: 30)

            // Stethoscope on suitcase
            StethoscopeShape()
                .stroke(TNColors.success, lineWidth: 4)
                .frame(width: 50, height: 50)
                .offset(x: 20, y: 10)

            // Medical cross badge
            MedicalCrossBadge()
                .frame(width: 40, height: 40)
                .offset(x: -35, y: -20)

            // Dollar signs floating
            ForEach(0..<3, id: \.self) { index in
                DollarSign()
                    .frame(width: 20, height: 20)
                    .offset(
                        x: CGFloat([-40, 45, 10][index]),
                        y: CGFloat([-50, -40, -65][index])
                    )
            }

            // Airplane
            Image(systemName: "airplane")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(TNColors.primary)
                .offset(x: 50, y: -55)
                .rotationEffect(.degrees(-30))
        }
    }
}

// MARK: - Suitcase Shape

struct SuitcaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 12

        // Main body
        path.addRoundedRect(
            in: CGRect(x: 0, y: rect.height * 0.15, width: rect.width, height: rect.height * 0.85),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )

        // Handle
        let handleWidth: CGFloat = rect.width * 0.3
        let handleHeight: CGFloat = rect.height * 0.2
        let handleX = (rect.width - handleWidth) / 2

        path.addRoundedRect(
            in: CGRect(x: handleX, y: 0, width: handleWidth, height: handleHeight),
            cornerSize: CGSize(width: 4, height: 4)
        )

        return path
    }
}

// MARK: - Stethoscope Shape

struct StethoscopeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // U-shaped tube
        path.move(to: CGPoint(x: rect.width * 0.2, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.5),
            control: CGPoint(x: rect.width * 0.5, y: rect.height)
        )
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: 0))

        return path
    }
}

// MARK: - Medical Cross Badge

struct MedicalCrossBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)

            // Cross
            VStack(spacing: 0) {
                Rectangle()
                    .fill(TNColors.error)
                    .frame(width: 8, height: 20)
            }

            HStack(spacing: 0) {
                Rectangle()
                    .fill(TNColors.error)
                    .frame(width: 20, height: 8)
            }
        }
    }
}

// MARK: - Dollar Sign

struct DollarSign: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(TNColors.success.opacity(0.2))

            Text("$")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(TNColors.success)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingWelcomeView(
        onContinue: {},
        onContinueAnonymous: {},
        onAlreadyMember: {}
    )
}
