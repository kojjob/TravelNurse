//
//  PaywallView.swift
//  TravelNurse
//
//  Subscription paywall with feature comparison and pricing
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features comparison
                    featuresSection

                    // Pricing cards
                    pricingSection

                    // Subscribe button
                    subscribeButton

                    // Restore purchases
                    restoreButton

                    // Terms
                    termsSection
                }
                .padding()
            }
            .background(TNColors.background)
            .navigationTitle("Upgrade to Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let yearly = subscriptionManager.yearlyProduct {
                    selectedProduct = yearly
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [TNColors.primary, TNColors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Unlock Your Full Potential")
                .font(.title2)
                .fontWeight(.bold)

            Text("Get AI-powered tools designed specifically for travel nurses to maximize your tax savings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    featureRow(feature)
                }
            }
            .padding()
            .background(TNColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func featureRow(_ feature: PremiumFeature) -> some View {
        HStack(spacing: 12) {
            Image(systemName: feature.iconName)
                .font(.title3)
                .foregroundStyle(TNColors.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading && subscriptionManager.products.isEmpty {
                ProgressView()
                    .padding()
            } else {
                // Yearly (Best Value)
                if let yearly = subscriptionManager.yearlyProduct {
                    pricingCard(
                        product: yearly,
                        badge: "SAVE 40%",
                        isSelected: selectedProduct?.id == yearly.id
                    )
                }

                // Monthly
                if let monthly = subscriptionManager.monthlyProduct {
                    pricingCard(
                        product: monthly,
                        badge: nil,
                        isSelected: selectedProduct?.id == monthly.id
                    )
                }
            }
        }
    }

    private func pricingCard(product: Product, badge: String?, isSelected: Bool) -> some View {
        Button {
            selectedProduct = product
            HapticManager.lightImpact()
        } label: {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(product.id.contains("yearly") ? "Annual" : "Monthly")
                                .font(.headline)

                            if let badge {
                                Text(badge)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(TNColors.success)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        if product.id.contains("yearly") {
                            Text("7-day free trial")
                                .font(.caption)
                                .foregroundStyle(TNColors.primary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(product.id.contains("yearly") ? "/year" : "/month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? TNColors.primary.opacity(0.1) : TNColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? TNColors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(selectedProduct?.id.contains("yearly") == true ? "Start Free Trial" : "Subscribe Now")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(TNColors.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionManager.restorePurchases()
                if subscriptionManager.isPremium {
                    dismiss()
                } else if let error = subscriptionManager.errorMessage {
                    errorMessage = error
                    showError = true
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(TNColors.primary)
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://travelnurse.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://travelnurse.app/privacy")!)
            }
            .font(.caption2)
        }
        .padding(.top)
    }

    // MARK: - Actions

    private func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
