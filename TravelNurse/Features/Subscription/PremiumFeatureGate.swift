//
//  PremiumFeatureGate.swift
//  TravelNurse
//
//  View modifier and wrapper for gating premium features
//

import SwiftUI

/// A view that gates access to premium features
struct PremiumFeatureGate<Content: View>: View {
    let feature: PremiumFeature
    let content: () -> Content

    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    init(feature: PremiumFeature, @ViewBuilder content: @escaping () -> Content) {
        self.feature = feature
        self.content = content
    }

    var body: some View {
        Group {
            if subscriptionManager.canAccess(feature) {
                content()
            } else {
                lockedView
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var lockedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(TNColors.primary.opacity(0.6))

            VStack(spacing: 8) {
                Text(feature.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                showPaywall = true
                HapticManager.lightImpact()
            } label: {
                Text("Unlock Premium")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TNColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TNColors.background)
    }
}

/// View modifier for premium feature access
struct PremiumFeatureModifier: ViewModifier {
    let feature: PremiumFeature
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if !subscriptionManager.canAccess(feature) {
                    showPaywall = true
                    HapticManager.lightImpact()
                }
            }
            .allowsHitTesting(subscriptionManager.canAccess(feature))
            .opacity(subscriptionManager.canAccess(feature) ? 1 : 0.6)
            .overlay {
                if !subscriptionManager.canAccess(feature) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPaywall = true
                            HapticManager.lightImpact()
                        }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
    }
}

extension View {
    /// Gate this view behind a premium feature
    func premiumFeature(_ feature: PremiumFeature) -> some View {
        modifier(PremiumFeatureModifier(feature: feature))
    }
}

/// A button that shows the paywall for non-premium users
struct PremiumButton<Label: View>: View {
    let feature: PremiumFeature
    let action: () -> Void
    let label: () -> Label

    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    init(
        feature: PremiumFeature,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.feature = feature
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            if subscriptionManager.canAccess(feature) {
                action()
            } else {
                showPaywall = true
                HapticManager.lightImpact()
            }
        } label: {
            HStack {
                label()

                if !subscriptionManager.canAccess(feature) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// Compact upgrade banner to show in free tier
struct UpgradeBanner: View {
    @State private var showPaywall = false

    var body: some View {
        Button {
            showPaywall = true
            HapticManager.lightImpact()
        } label: {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)

                Text("Upgrade to Premium")
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [TNColors.primary.opacity(0.1), TNColors.accent.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

/// Document limit warning view
struct DocumentLimitWarning: View {
    let currentCount: Int
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false

    var isAtLimit: Bool {
        !subscriptionManager.isPremium && currentCount >= subscriptionManager.documentLimit
    }

    var remainingDocuments: Int {
        max(0, subscriptionManager.documentLimit - currentCount)
    }

    var body: some View {
        if !subscriptionManager.isPremium {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(isAtLimit ? .red : TNColors.primary)

                    Text("\(currentCount)/\(subscriptionManager.documentLimit) documents")
                        .font(.subheadline)

                    Spacer()

                    if isAtLimit {
                        Button("Upgrade") {
                            showPaywall = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(TNColors.primary)
                    }
                }

                if isAtLimit {
                    Text("You've reached the free document limit. Upgrade to Premium for unlimited storage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(isAtLimit ? Color.red.opacity(0.1) : TNColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Preview

#Preview("Locked Feature") {
    PremiumFeatureGate(feature: .aiTaxAssistant) {
        Text("Premium Content")
    }
}

#Preview("Upgrade Banner") {
    UpgradeBanner()
        .padding()
}

#Preview("Document Warning") {
    VStack {
        DocumentLimitWarning(currentCount: 3)
        DocumentLimitWarning(currentCount: 5)
    }
    .padding()
}
