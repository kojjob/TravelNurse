//
//  OnboardingSignInView.swift
//  TravelNurse
//
//  Sign in screen with Apple authentication for onboarding
//

import SwiftUI
import AuthenticationServices

/// Sign in screen - handles Apple authentication
struct OnboardingSignInView: View {

    @Bindable var manager: OnboardingManager
    let onComplete: () -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Animation states
    @State private var contentOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 50

    var body: some View {
        ZStack {
            // Warm gradient background
            backgroundGradient

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Header
                headerSection
                    .opacity(contentOpacity)

                Spacer()
                    .frame(height: 40)

                // Illustration
                signInIllustration
                    .opacity(contentOpacity)

                Spacer()

                // Sign in buttons
                signInSection
                    .opacity(contentOpacity)
                    .offset(y: buttonOffset)

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
                Color(hex: "FFF5EB"),
                Color(hex: "FFE4CC"),
                Color(hex: "FFECD2")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Create Your Account")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)

            Text("Sign in to sync your data across devices and never lose your records")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(TNColors.textSecondaryLight)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Sign In Illustration

    private var signInIllustration: some View {
        ZStack {
            // Blue circle background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [TNColors.primary.opacity(0.2), TNColors.primary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)

            // Shield with lock icon
            VStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(TNColors.primary)

                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(TNColors.secondary)
            }
        }
    }

    // MARK: - Sign In Section

    private var signInSection: some View {
        VStack(spacing: 16) {
            // Sign in with Apple button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleSignInResult(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 28))

            // Skip button
            Button(action: onSkip) {
                Text("Skip for now")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)
            }
            .padding(.top, 8)

            // Privacy notice
            privacyNotice
        }
    }

    // MARK: - Privacy Notice

    private var privacyNotice: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(TNColors.secondary)

                Text("Your data is encrypted and secure")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TNColors.textSecondaryLight)
            }

            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(TNColors.textTertiaryLight)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    // MARK: - Sign In Handler

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let displayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                manager.signInWithApple(
                    userId: userId,
                    name: displayName.isEmpty ? "Traveler" : displayName
                )
                onComplete()
            }

        case .failure(let error):
            // User cancelled or error occurred
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Animation

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            contentOpacity = 1
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3)) {
            buttonOffset = 0
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingSignInView(
        manager: OnboardingManager(),
        onComplete: {},
        onSkip: {}
    )
}
