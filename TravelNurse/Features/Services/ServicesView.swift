//
//  ServicesView.swift
//  TravelNurse
//
//  Hub view displaying all app features as a grid
//

import SwiftUI

/// Hub view showing all app features/services
struct ServicesView: View {

    @State private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TNSpacing.lg) {
                    // Core Features Section
                    featureSection(
                        title: "Core Features",
                        features: coreFeatures
                    )

                    // Tax & Compliance Section
                    featureSection(
                        title: "Tax & Compliance",
                        features: taxFeatures
                    )

                    // AI Features Section (Premium)
                    featureSection(
                        title: "AI Features",
                        features: aiFeatures,
                        isPremium: true
                    )

                    // Tools Section
                    featureSection(
                        title: "Tools",
                        features: toolFeatures
                    )
                }
                .padding(.horizontal, TNSpacing.md)
                .padding(.bottom, TNSpacing.xl)
            }
            .background(TNColors.background)
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Feature Definitions

    private var coreFeatures: [ServiceFeature] {
        [
            ServiceFeature(
                title: "Expenses",
                subtitle: "Track deductions",
                icon: "creditcard.fill",
                color: TNColors.primary,
                destination: AnyView(ExpenseListView())
            ),
            ServiceFeature(
                title: "Assignments",
                subtitle: "Manage contracts",
                icon: "briefcase.fill",
                color: TNColors.secondary,
                destination: AnyView(AssignmentListView())
            ),
            ServiceFeature(
                title: "Mileage",
                subtitle: "Track travel",
                icon: "car.fill",
                color: TNColors.accent,
                destination: AnyView(MileageListView())
            ),
            ServiceFeature(
                title: "Documents",
                subtitle: "Secure vault",
                icon: "doc.fill",
                color: TNColors.info,
                destination: AnyView(DocumentVaultView())
            )
        ]
    }

    private var taxFeatures: [ServiceFeature] {
        [
            ServiceFeature(
                title: "Tax Home",
                subtitle: "Compliance tracking",
                icon: "house.fill",
                color: TNColors.success,
                destination: AnyView(TaxHomeView())
            ),
            ServiceFeature(
                title: "Reports",
                subtitle: "Tax summaries",
                icon: "chart.bar.fill",
                color: TNColors.warning,
                destination: AnyView(ReportsView())
            ),
            ServiceFeature(
                title: "Licenses",
                subtitle: "Track credentials",
                icon: "checkmark.seal.fill",
                color: TNColors.secondary,
                destination: AnyView(LicenseListView())
            )
        ]
    }

    private var aiFeatures: [ServiceFeature] {
        [
            ServiceFeature(
                title: "Tax Assistant",
                subtitle: "AI help",
                icon: "brain.head.profile",
                color: TNColors.primary,
                destination: AnyView(TaxAssistantView()),
                isPremium: true
            ),
            ServiceFeature(
                title: "Quick Add",
                subtitle: "Smart expense entry",
                icon: "wand.and.stars",
                color: TNColors.accent,
                destination: AnyView(QuickAddExpenseView()),
                isPremium: true
            )
        ]
    }

    private var toolFeatures: [ServiceFeature] {
        [
            ServiceFeature(
                title: "Calculator",
                subtitle: "Stipend calculator",
                icon: "function",
                color: TNColors.textSecondary,
                destination: AnyView(StipendCalculatorView())
            )
        ]
    }

    // MARK: - Section View

    private func featureSection(title: String, features: [ServiceFeature], isPremium: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: TNSpacing.sm) {
            HStack {
                Text(title)
                    .font(TNTypography.titleSmall)
                    .foregroundColor(TNColors.textPrimary)

                if isPremium && !subscriptionManager.isPremium {
                    Label("Premium", systemImage: "crown.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TNColors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(TNColors.warning.opacity(0.15))
                        .clipShape(Capsule())
                }

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: TNSpacing.md),
                GridItem(.flexible(), spacing: TNSpacing.md)
            ], spacing: TNSpacing.md) {
                ForEach(features) { feature in
                    ServiceCard(
                        feature: feature,
                        isLocked: feature.isPremium && !subscriptionManager.isPremium
                    )
                }
            }
        }
    }
}

// MARK: - Service Feature Model

struct ServiceFeature: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: AnyView
    var isPremium: Bool = false
}

// MARK: - Service Card

struct ServiceCard: View {
    let feature: ServiceFeature
    let isLocked: Bool

    @State private var showPaywall = false

    var body: some View {
        Group {
            if isLocked {
                Button {
                    showPaywall = true
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    feature.destination
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var cardContent: some View {
        VStack(spacing: TNSpacing.sm) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.color)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(TNColors.textSecondary)
                        .clipShape(Circle())
                        .offset(x: 20, y: 20)
                }
            }

            VStack(spacing: 2) {
                Text(feature.title)
                    .font(TNTypography.labelMedium)
                    .foregroundColor(TNColors.textPrimary)

                Text(feature.subtitle)
                    .font(TNTypography.caption)
                    .foregroundColor(TNColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TNSpacing.lg)
        .background(TNColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: TNSpacing.radiusMD))
        .shadow(color: TNColors.cardShadow, radius: 4, x: 0, y: 2)
        .opacity(isLocked ? 0.7 : 1)
    }
}

// MARK: - Preview

#Preview {
    ServicesView()
}
