//
//  OnboardingContainerView.swift
//  TravelNurse
//
//  Main container that orchestrates the onboarding flow
//

import SwiftUI

/// Main onboarding container - manages flow between all onboarding screens
struct OnboardingContainerView: View {

    @State private var manager = OnboardingManager()
    @Binding var showOnboarding: Bool

    var body: some View {
        ZStack {
            // Page content based on current state
            Group {
                switch manager.currentPage {
                case .welcome:
                    OnboardingWelcomeView(
                        onContinue: {
                            manager.nextPage()
                        },
                        onContinueAnonymous: {
                            manager.continueAnonymously()
                        },
                        onAlreadyMember: {
                            // Navigate to sign in
                            manager.currentPage = .signIn
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))

                case .signIn:
                    OnboardingSignInView(
                        manager: manager,
                        onComplete: {
                            // Sign in successful, go to goals
                            manager.currentPage = .goals
                        },
                        onSkip: {
                            manager.continueAnonymously()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

                case .goals:
                    OnboardingGoalsView(
                        manager: manager,
                        onContinue: {
                            manager.nextPage()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

                case .complete:
                    OnboardingCompleteView(
                        userName: manager.userName,
                        selectedGoalsCount: manager.selectedGoals.count,
                        onGetStarted: {
                            completeOnboarding()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .opacity
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: manager.currentPage)

            // Back button overlay (when not on welcome or complete)
            if manager.currentPage != .welcome && manager.currentPage != .complete {
                VStack {
                    HStack {
                        backButton
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()
                }
            }

            // Progress indicators (except on complete)
            if manager.currentPage != .complete {
                VStack {
                    Spacer()

                    progressIndicators
                        .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                manager.previousPage()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1A1A2E"))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        }
    }

    // MARK: - Progress Indicators

    private var progressIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        index <= currentProgressIndex
                            ? Color(hex: "1A1A2E")
                            : Color(hex: "1A1A2E").opacity(0.2)
                    )
                    .frame(width: index == currentProgressIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentProgressIndex)
            }
        }
    }

    private var currentProgressIndex: Int {
        switch manager.currentPage {
        case .welcome: return 0
        case .signIn: return 1
        case .goals: return 2
        case .complete: return 2
        }
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding() {
        manager.completeOnboarding()

        withAnimation(.easeOut(duration: 0.4)) {
            showOnboarding = false
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView(showOnboarding: .constant(true))
}
