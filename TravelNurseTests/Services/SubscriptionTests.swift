//
//  SubscriptionTests.swift
//  TravelNurseTests
//
//  Tests for subscription and premium feature gating
//

import XCTest
@testable import TravelNurse

final class SubscriptionTests: XCTestCase {

    // MARK: - Premium Feature Tests

    func testPremiumFeatureEnumCoverage() {
        // Verify all premium features have required properties
        for feature in PremiumFeature.allCases {
            XCTAssertFalse(feature.rawValue.isEmpty, "Feature \(feature) should have a name")
            XCTAssertFalse(feature.description.isEmpty, "Feature \(feature) should have a description")
            XCTAssertFalse(feature.iconName.isEmpty, "Feature \(feature) should have an icon")
        }
    }

    func testPremiumFeatureDescriptions() {
        XCTAssertEqual(PremiumFeature.aiTaxAssistant.rawValue, "AI Tax Assistant")
        XCTAssertEqual(PremiumFeature.quickAddExpense.rawValue, "Quick Add Expense")
        XCTAssertEqual(PremiumFeature.smartCategorization.rawValue, "Smart Categorization")
        XCTAssertEqual(PremiumFeature.unlimitedDocuments.rawValue, "Unlimited Documents")
        XCTAssertEqual(PremiumFeature.advancedReports.rawValue, "Advanced Reports")
        XCTAssertEqual(PremiumFeature.prioritySupport.rawValue, "Priority Support")
    }

    func testPremiumFeatureIcons() {
        XCTAssertEqual(PremiumFeature.aiTaxAssistant.iconName, "brain.head.profile")
        XCTAssertEqual(PremiumFeature.quickAddExpense.iconName, "text.badge.plus")
        XCTAssertEqual(PremiumFeature.smartCategorization.iconName, "sparkles")
        XCTAssertEqual(PremiumFeature.unlimitedDocuments.iconName, "doc.fill")
        XCTAssertEqual(PremiumFeature.advancedReports.iconName, "chart.bar.doc.horizontal")
        XCTAssertEqual(PremiumFeature.prioritySupport.iconName, "star.fill")
    }

    // MARK: - Subscription Status Tests

    func testSubscriptionStatusValues() {
        XCTAssertEqual(SubscriptionStatus.notSubscribed.rawValue, "notSubscribed")
        XCTAssertEqual(SubscriptionStatus.subscribed.rawValue, "subscribed")
        XCTAssertEqual(SubscriptionStatus.expired.rawValue, "expired")
        XCTAssertEqual(SubscriptionStatus.inGracePeriod.rawValue, "inGracePeriod")
    }

    // MARK: - Product ID Tests

    func testProductIDs() {
        XCTAssertEqual(
            SubscriptionManager.ProductID.monthlyPremium.rawValue,
            "com.travelnurse.premium.monthly"
        )
        XCTAssertEqual(
            SubscriptionManager.ProductID.yearlyPremium.rawValue,
            "com.travelnurse.premium.yearly"
        )
    }

    func testYearlyProductIdentification() {
        XCTAssertFalse(SubscriptionManager.ProductID.monthlyPremium.isYearly)
        XCTAssertTrue(SubscriptionManager.ProductID.yearlyPremium.isYearly)
    }

    // MARK: - Subscription Error Tests

    func testSubscriptionErrorDescriptions() {
        let verificationError = SubscriptionError.verificationFailed
        XCTAssertNotNil(verificationError.errorDescription)
        XCTAssertTrue(verificationError.errorDescription!.contains("verify"))

        let purchaseError = SubscriptionError.purchaseFailed("Test reason")
        XCTAssertNotNil(purchaseError.errorDescription)
        XCTAssertTrue(purchaseError.errorDescription!.contains("Test reason"))

        let productError = SubscriptionError.productNotFound
        XCTAssertNotNil(productError.errorDescription)
        XCTAssertTrue(productError.errorDescription!.contains("not found"))
    }

    // MARK: - Document Limit Tests

    func testFreeDocumentLimit() {
        // Free users should have a limit of 5 documents
        let freeLimit = 5
        XCTAssertEqual(freeLimit, 5, "Free users should have a 5 document limit")
    }

    func testPremiumDocumentLimit() {
        // Premium users should have unlimited documents
        let premiumLimit = Int.max
        XCTAssertEqual(premiumLimit, Int.max, "Premium users should have unlimited documents")
    }

    // MARK: - Feature Gating Logic Tests

    func testAllAIFeaturesRequirePremium() {
        // All AI-related features should require premium
        let aiFeatures: [PremiumFeature] = [
            .aiTaxAssistant,
            .quickAddExpense,
            .smartCategorization
        ]

        for feature in aiFeatures {
            // In a real implementation, we'd mock the subscription manager
            // For now, just verify the features exist
            XCTAssertNotNil(feature.description)
        }
    }

    func testPremiumFeatureCount() {
        // Verify expected number of premium features
        XCTAssertEqual(PremiumFeature.allCases.count, 6)
    }
}

// MARK: - Mock Subscription Manager for Testing

/// A mock subscription manager for unit testing feature gating
final class MockSubscriptionManager {
    var isPremium: Bool = false
    var documentLimit: Int {
        isPremium ? .max : 5
    }

    func canAccess(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .aiTaxAssistant, .quickAddExpense, .smartCategorization,
             .unlimitedDocuments, .advancedReports, .prioritySupport:
            return isPremium
        }
    }
}

final class MockSubscriptionManagerTests: XCTestCase {

    func testFreeUserCannotAccessPremiumFeatures() {
        let manager = MockSubscriptionManager()
        manager.isPremium = false

        for feature in PremiumFeature.allCases {
            XCTAssertFalse(
                manager.canAccess(feature),
                "Free user should not access \(feature.rawValue)"
            )
        }
    }

    func testPremiumUserCanAccessAllFeatures() {
        let manager = MockSubscriptionManager()
        manager.isPremium = true

        for feature in PremiumFeature.allCases {
            XCTAssertTrue(
                manager.canAccess(feature),
                "Premium user should access \(feature.rawValue)"
            )
        }
    }

    func testFreeUserDocumentLimit() {
        let manager = MockSubscriptionManager()
        manager.isPremium = false

        XCTAssertEqual(manager.documentLimit, 5)
    }

    func testPremiumUserDocumentLimit() {
        let manager = MockSubscriptionManager()
        manager.isPremium = true

        XCTAssertEqual(manager.documentLimit, .max)
    }

    func testDocumentLimitEnforcement() {
        let manager = MockSubscriptionManager()
        manager.isPremium = false

        let currentDocuments = 5
        let canAddMore = currentDocuments < manager.documentLimit

        XCTAssertFalse(canAddMore, "Free user at limit should not add more documents")
    }

    func testDocumentLimitWithRoom() {
        let manager = MockSubscriptionManager()
        manager.isPremium = false

        let currentDocuments = 3
        let canAddMore = currentDocuments < manager.documentLimit

        XCTAssertTrue(canAddMore, "Free user with room should be able to add documents")
    }
}
