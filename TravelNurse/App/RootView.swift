//
//  RootView.swift
//  TravelNurse
//
//  Root view that manages navigation between onboarding and main app
//

import SwiftUI

/// Root view that determines whether to show onboarding or main app
struct RootView: View {

    /// Tracks whether onboarding has been completed
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// Controls onboarding presentation
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingContainerView(showOnboarding: $showOnboarding)
                    .transition(.opacity)
                    .onDisappear {
                        // Sync with AppStorage when onboarding completes
                        if !showOnboarding {
                            hasCompletedOnboarding = true
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .onAppear {
            showOnboarding = !hasCompletedOnboarding
        }
        .onChange(of: showOnboarding) { _, newValue in
            if !newValue {
                withAnimation(.easeInOut(duration: 0.4)) {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("First Launch") {
    RootView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}

#Preview("Returning User") {
    RootView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        }
}
