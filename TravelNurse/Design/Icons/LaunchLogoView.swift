//
//  LaunchLogoView.swift
//  TravelNurse
//
//  Animated launch screen logo with elegant reveal animation
//

import SwiftUI

// MARK: - Launch Logo View
struct LaunchLogoView: View {
    @State private var isAnimating = false
    @State private var showTagline = false

    // Brand colors from design tokens
    private let primaryBlue = TNColors.primary
    private let darkBlue = TNColors.primaryDark
    private let accentGreen = TNColors.secondary

    var body: some View {
        ZStack {
            // Animated background gradient
            backgroundGradient

            VStack(spacing: 24) {
                // Animated logo mark
                animatedLogoMark

                // App name with staggered reveal
                appNameSection

                // Tagline
                taglineSection
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showTagline = true
            }
        }
    }

    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "F8FAFC"),
                    Color(hex: "EEF2FF"),
                    Color(hex: "F8FAFC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow behind logo
            RadialGradient(
                colors: [
                    primaryBlue.opacity(0.08),
                    primaryBlue.opacity(0.02),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 1 : 0)

            // Decorative circles
            Circle()
                .fill(primaryBlue.opacity(0.03))
                .frame(width: 400, height: 400)
                .offset(x: -150, y: -300)
                .blur(radius: 60)

            Circle()
                .fill(accentGreen.opacity(0.04))
                .frame(width: 300, height: 300)
                .offset(x: 180, y: 350)
                .blur(radius: 50)
        }
        .ignoresSafeArea()
    }

    // MARK: - Animated Logo Mark
    private var animatedLogoMark: some View {
        ZStack {
            // Glow effect
            LogoIconMark(size: 140, primaryColor: primaryBlue, accentColor: accentGreen)
                .blur(radius: 20)
                .opacity(isAnimating ? 0.4 : 0)
                .scaleEffect(isAnimating ? 1.15 : 0.9)

            // Main logo
            LogoIconMark(size: 120, primaryColor: primaryBlue, accentColor: accentGreen)
                .scaleEffect(isAnimating ? 1.0 : 0.6)
                .opacity(isAnimating ? 1 : 0)
        }
        .shadow(color: primaryBlue.opacity(0.25), radius: 30, x: 0, y: 15)
    }

    // MARK: - App Name Section
    private var appNameSection: some View {
        VStack(spacing: 4) {
            Text("TravelNurse")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(TNColors.textPrimaryLight)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

            Text("TAX COMPANION")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .tracking(3)
                .foregroundColor(primaryBlue)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 15)
        }
    }

    // MARK: - Tagline Section
    private var taglineSection: some View {
        Text("Protecting your finances, wherever you go")
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(TNColors.textSecondaryLight)
            .multilineTextAlignment(.center)
            .opacity(showTagline ? 1 : 0)
            .offset(y: showTagline ? 0 : 10)
            .padding(.top, 8)
    }
}

// MARK: - Dark Mode Launch Logo
struct LaunchLogoDarkView: View {
    @State private var isAnimating = false
    @State private var showTagline = false

    private let primaryBlue = TNColors.primary
    private let accentGreen = TNColors.secondary

    var body: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [
                    Color(hex: "0F172A"),
                    Color(hex: "1E293B"),
                    Color(hex: "0F172A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Glow effects
            RadialGradient(
                colors: [
                    primaryBlue.opacity(0.15),
                    primaryBlue.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 250
            )
            .scaleEffect(isAnimating ? 1.3 : 0.8)
            .opacity(isAnimating ? 1 : 0)

            VStack(spacing: 24) {
                // Logo with glow
                ZStack {
                    LogoIconMark(size: 140, primaryColor: primaryBlue, accentColor: accentGreen)
                        .blur(radius: 25)
                        .opacity(isAnimating ? 0.5 : 0)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)

                    LogoIconMark(size: 120, primaryColor: primaryBlue, accentColor: accentGreen)
                        .scaleEffect(isAnimating ? 1.0 : 0.6)
                        .opacity(isAnimating ? 1 : 0)
                }
                .shadow(color: primaryBlue.opacity(0.4), radius: 40, x: 0, y: 20)

                VStack(spacing: 4) {
                    Text("TravelNurse")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)

                    Text("TAX COMPANION")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .tracking(3)
                        .foregroundColor(primaryBlue)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 15)
                }

                Text("Protecting your finances, wherever you go")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "94A3B8"))
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 10)
                    .padding(.top, 8)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showTagline = true
            }
        }
    }
}

// MARK: - Minimal Launch Screen (for LaunchScreen.storyboard replacement)
struct MinimalLaunchView: View {
    private let primaryBlue = TNColors.primary
    private let accentGreen = TNColors.secondary

    var body: some View {
        ZStack {
            TNColors.backgroundLight
                .ignoresSafeArea()

            LogoIconMark(size: 100, primaryColor: primaryBlue, accentColor: accentGreen)
                .shadow(color: primaryBlue.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Previews
#Preview("Launch Logo - Light") {
    LaunchLogoView()
}

#Preview("Launch Logo - Dark") {
    LaunchLogoDarkView()
}

#Preview("Minimal Launch") {
    MinimalLaunchView()
}

#Preview("Launch Animation Sequence") {
    TabView {
        MinimalLaunchView()
            .tabItem { Text("Minimal") }

        LaunchLogoView()
            .tabItem { Text("Light") }

        LaunchLogoDarkView()
            .tabItem { Text("Dark") }
    }
}
