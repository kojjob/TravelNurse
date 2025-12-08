//
//  SubscriptionManager.swift
//  TravelNurse
//
//  Manages StoreKit 2 subscriptions and premium feature access
//

import Foundation
import StoreKit

/// Manages app subscriptions using StoreKit 2
@MainActor
@Observable
final class SubscriptionManager {

    // MARK: - Singleton

    static let shared = SubscriptionManager()

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.travelnurse.premium.monthly"
        case yearlyPremium = "com.travelnurse.premium.yearly"

        var isYearly: Bool {
            self == .yearlyPremium
        }
    }

    // MARK: - Published Properties

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Computed Properties

    var isPremium: Bool {
        subscriptionStatus == .subscribed
    }

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium.rawValue }
    }

    var currentSubscription: Product? {
        products.first { purchasedProductIDs.contains($0.id) }
    }

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    /// Load available products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Purchase a subscription product
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                isLoading = false
                return true

            case .userCancelled:
                isLoading = false
                return false

            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            isLoading = false

            if !isPremium {
                errorMessage = "No active subscription found"
            }
        } catch {
            isLoading = false
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    /// Update current subscription status
    func updateSubscriptionStatus() async {
        var activePurchases: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                activePurchases.insert(transaction.productID)
            }
        }

        purchasedProductIDs = activePurchases
        subscriptionStatus = activePurchases.isEmpty ? .notSubscribed : .subscribed
    }

    // MARK: - Feature Access

    /// Check if a specific premium feature is accessible
    func canAccess(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .aiTaxAssistant, .quickAddExpense, .smartCategorization:
            return isPremium
        case .unlimitedDocuments:
            return isPremium
        case .advancedReports:
            return isPremium
        case .prioritySupport:
            return isPremium
        }
    }

    /// Get the document limit for current subscription tier
    var documentLimit: Int {
        isPremium ? .max : 5
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                await transaction.finish()
                await self.updateSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Supporting Types

enum SubscriptionStatus: String, Sendable {
    case notSubscribed
    case subscribed
    case expired
    case inGracePeriod
}

enum PremiumFeature: String, CaseIterable, Sendable {
    case aiTaxAssistant = "AI Tax Assistant"
    case quickAddExpense = "Quick Add Expense"
    case smartCategorization = "Smart Categorization"
    case unlimitedDocuments = "Unlimited Documents"
    case advancedReports = "Advanced Reports"
    case prioritySupport = "Priority Support"

    var description: String {
        switch self {
        case .aiTaxAssistant:
            return "Get instant answers to travel nurse tax questions"
        case .quickAddExpense:
            return "Add expenses using natural language"
        case .smartCategorization:
            return "AI automatically categorizes your expenses"
        case .unlimitedDocuments:
            return "Store unlimited documents in your vault"
        case .advancedReports:
            return "Detailed tax reports and analytics"
        case .prioritySupport:
            return "Get help faster when you need it"
        }
    }

    var iconName: String {
        switch self {
        case .aiTaxAssistant:
            return "brain.head.profile"
        case .quickAddExpense:
            return "text.badge.plus"
        case .smartCategorization:
            return "sparkles"
        case .unlimitedDocuments:
            return "doc.fill"
        case .advancedReports:
            return "chart.bar.doc.horizontal"
        case .prioritySupport:
            return "star.fill"
        }
    }
}

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed(String)
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Could not verify the purchase. Please try again."
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .productNotFound:
            return "Subscription product not found."
        }
    }
}
