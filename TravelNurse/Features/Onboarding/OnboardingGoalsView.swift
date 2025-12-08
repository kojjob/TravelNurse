//
//  OnboardingGoalsView.swift
//  TravelNurse
//
//  Goals selection screen for onboarding - customize app for user needs
//

import SwiftUI

/// Goals selection screen - allows users to select what features matter most
struct OnboardingGoalsView: View {

    @Bindable var manager: OnboardingManager
    let onContinue: () -> Void

    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var cardsOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            // Warm gradient background
            backgroundGradient

            VStack(spacing: 0) {
                // Header section
                headerSection
                    .opacity(headerOpacity)
                    .padding(.top, 60)

                Spacer()
                    .frame(height: 32)

                // Goals grid
                ScrollView(showsIndicators: false) {
                    goalsGrid
                        .opacity(cardsOpacity)
                }
                .scrollClipDisabled()  // Allow checkmarks to render outside scroll bounds

                Spacer()

                // Continue button
                continueButton
                    .opacity(buttonOpacity)
                    .padding(.bottom, 40)
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
                Color(hex: "FFF5EB"),  // Cream
                Color(hex: "FFE4CC"),  // Light peach
                Color(hex: "FFECD2")   // Soft peach
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("How can we help?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(TNColors.textPrimaryLight)

            Text("Tell us what you're interested in so we can customize the app for your needs")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(TNColors.textSecondaryLight)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Goals Grid

    private var goalsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(OnboardingGoal.allCases) { goal in
                GoalCard(
                    goal: goal,
                    isSelected: manager.isGoalSelected(goal),
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            manager.toggleGoal(goal)
                        }
                    }
                )
            }
        }
        // Padding to accommodate checkmark overflow (8pt offset + 12pt radius = 20pt)
        .padding(.top, 20)
        .padding(.trailing, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))

                if !manager.selectedGoals.isEmpty {
                    Text("(\(manager.selectedGoals.count))")
                        .font(.system(size: 15, weight: .medium))
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                manager.selectedGoals.isEmpty
                    ? TNColors.textPrimaryLight.opacity(0.5)
                    : TNColors.textPrimaryLight
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .disabled(manager.selectedGoals.isEmpty)
    }

    // MARK: - Animation

    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            headerOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            cardsOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            buttonOpacity = 1
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(goal.iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: goal.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(goal.iconColor)
                }

                // Text content
                VStack(spacing: 4) {
                    Text(goal.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(TNColors.textPrimaryLight)

                    Text(goal.description)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(TNColors.textSecondaryLight)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? goal.iconColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(alignment: .topTrailing) {
                // Checkmark indicator
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(goal.iconColor)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                }
            }
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OnboardingGoalsView(
        manager: OnboardingManager(),
        onContinue: {}
    )
}
