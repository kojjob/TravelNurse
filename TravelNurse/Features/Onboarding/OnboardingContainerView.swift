//
//  OnboardingContainerView.swift
//  TravelNurse
//
//  Enhanced container that orchestrates the onboarding flow
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
                            // Skip to goals for returning users
                            manager.skipToGoals()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))

                case .profile:
                    ProfileSetupView(
                        manager: manager,
                        onContinue: {
                            manager.nextPage()
                        },
                        onSkip: {
                            manager.firstName = "Traveler"
                            manager.skipToPage(.taxHome)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

                case .taxHome:
                    TaxHomeSetupView(
                        manager: manager,
                        onContinue: {
                            manager.nextPage()
                        },
                        onSkip: {
                            manager.taxHomeState = nil
                            manager.taxHomeCity = ""
                            manager.taxHomeZipCode = ""
                            manager.nextPage()
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
                        userName: manager.fullName,
                        selectedGoalsCount: manager.selectedGoals.count,
                        summary: manager.summary,
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

                    VStack(spacing: 8) {
                        // Progress bar
                        progressBar

                        // Step indicator
                        stepIndicator
                    }
                    .padding(.bottom, 16)
                    .padding(.horizontal, 24)
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
                .foregroundColor(TNColors.textPrimaryLight)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 6)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [TNColors.primary, TNColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * manager.progressPercentage, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: manager.progressPercentage)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            Text("Step \(manager.currentPage.rawValue + 1)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(TNColors.textPrimaryLight.opacity(0.8))

            Text("of \(OnboardingPage.allCases.count)")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(TNColors.textSecondaryLight.opacity(0.7))
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
