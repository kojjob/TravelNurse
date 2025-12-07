//
//  SettingsViewModel.swift
//  TravelNurse
//
//  ViewModel for Settings screen - profile, preferences, and app settings
//

import Foundation
import SwiftUI
import UIKit
import StoreKit

/// User profile display data for settings screen
/// Note: This is separate from the domain UserProfile model to allow
/// for settings-specific display properties
struct SettingsProfileData {
    var firstName: String
    var lastName: String
    var email: String
    var nursingLicense: String?
    var specialty: String?
    var yearsExperience: Int?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    static var placeholder: SettingsProfileData {
        SettingsProfileData(
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah.johnson@email.com",
            nursingLicense: "RN-123456",
            specialty: "ICU/Critical Care",
            yearsExperience: 8
        )
    }
}

/// Tax home address data
struct TaxHomeAddress {
    var street: String
    var city: String
    var state: USState
    var zipCode: String

    var formatted: String {
        "\(city), \(state.rawValue)"
    }

    var fullAddress: String {
        "\(street)\n\(city), \(state.rawValue) \(zipCode)"
    }

    static var placeholder: TaxHomeAddress {
        TaxHomeAddress(
            street: "123 Main Street",
            city: "Nashville",
            state: .tennessee,
            zipCode: "37201"
        )
    }
}

/// Notification preferences
struct NotificationPreferences: Codable, Equatable {
    var pushEnabled: Bool
    var emailEnabled: Bool
    var taxDeadlineReminders: Bool
    var assignmentReminders: Bool
    var expenseReminders: Bool
    var weeklyDigest: Bool

    static var defaults: NotificationPreferences {
        NotificationPreferences(
            pushEnabled: true,
            emailEnabled: true,
            taxDeadlineReminders: true,
            assignmentReminders: true,
            expenseReminders: false,
            weeklyDigest: true
        )
    }
}

/// Privacy settings
struct PrivacySettings: Codable, Equatable {
    var analyticsEnabled: Bool
    var crashReportingEnabled: Bool
    var locationTrackingEnabled: Bool

    static var defaults: PrivacySettings {
        PrivacySettings(
            analyticsEnabled: true,
            crashReportingEnabled: true,
            locationTrackingEnabled: true
        )
    }
}

/// App appearance mode
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// Settings section types
enum SettingsSection: String, CaseIterable, Identifiable {
    case profile = "Profile"
    case taxHome = "Tax Home"
    case notifications = "Notifications"
    case appearance = "Appearance"
    case privacy = "Privacy & Data"
    case support = "Support"
    case about = "About"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .profile: return "person.circle.fill"
        case .taxHome: return "house.fill"
        case .notifications: return "bell.fill"
        case .appearance: return "paintbrush.fill"
        case .privacy: return "hand.raised.fill"
        case .support: return "questionmark.circle.fill"
        case .about: return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .profile: return TNColors.primary
        case .taxHome: return TNColors.success
        case .notifications: return TNColors.warning
        case .appearance: return TNColors.accent
        case .privacy: return TNColors.error
        case .support: return TNColors.secondary
        case .about: return TNColors.textSecondary
        }
    }
}

/// ViewModel managing Settings screen state
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - UserDefaults Keys

    private nonisolated(unsafe) static let notificationPreferencesKey = "settings.notificationPreferences"
    private nonisolated(unsafe) static let privacySettingsKey = "settings.privacySettings"
    private nonisolated(unsafe) static let appearanceModeKey = "settings.appearanceMode"

    // MARK: - State

    /// User profile
    private(set) var profile: SettingsProfileData = .placeholder

    /// Tax home address
    private(set) var taxHomeAddress: TaxHomeAddress = .placeholder

    /// Tax home compliance status
    private(set) var taxHomeComplianceScore: Double = 0.85

    /// Notification preferences
    var notificationPreferences: NotificationPreferences = .defaults

    /// Privacy settings
    var privacySettings: PrivacySettings = .defaults

    /// Appearance mode
    var appearanceMode: AppearanceMode = .system

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Show error alert
    var showError = false

    /// Show edit profile sheet
    var showEditProfile = false

    /// Show edit tax home sheet
    var showEditTaxHome = false

    /// Show export data confirmation
    var showExportConfirmation = false

    /// Show delete account confirmation
    var showDeleteConfirmation = false

    // MARK: - Dependencies

    private let serviceContainer: ServiceContainer

    // MARK: - Computed Properties

    /// App version string
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    /// Formatted compliance score
    var formattedComplianceScore: String {
        "\(Int(taxHomeComplianceScore * 100))%"
    }

    /// Compliance status description
    var complianceStatus: String {
        switch taxHomeComplianceScore {
        case 0.9...1.0: return "Excellent"
        case 0.7..<0.9: return "Good"
        case 0.5..<0.7: return "Needs Attention"
        default: return "At Risk"
        }
    }

    /// Compliance status color
    var complianceStatusColor: Color {
        switch taxHomeComplianceScore {
        case 0.9...1.0: return TNColors.success
        case 0.7..<0.9: return TNColors.primary
        case 0.5..<0.7: return TNColors.warning
        default: return TNColors.error
        }
    }

    /// Days at tax home this year
    var daysAtTaxHome: Int {
        // Simplified calculation - in production would calculate from actual data
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Int(Double(dayOfYear) * 0.35) // ~35% of days at tax home
    }

    /// Support email
    var supportEmail: String {
        "support@travelnurseapp.com"
    }

    /// Privacy policy URL
    var privacyPolicyURL: URL? {
        URL(string: "https://travelnurseapp.com/privacy")
    }

    /// Terms of service URL
    var termsOfServiceURL: URL? {
        URL(string: "https://travelnurseapp.com/terms")
    }

    // MARK: - Initialization

    init(serviceContainer: ServiceContainer = .shared) {
        self.serviceContainer = serviceContainer
    }

    // MARK: - Persistence

    /// Load persisted settings from UserDefaults
    private func loadPersistedSettings() {
        let defaults = UserDefaults.standard

        // Load notification preferences
        if let data = defaults.data(forKey: Self.notificationPreferencesKey),
           let decoded = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.notificationPreferences = decoded
        }

        // Load privacy settings
        if let data = defaults.data(forKey: Self.privacySettingsKey),
           let decoded = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            self.privacySettings = decoded
        }

        // Load appearance mode
        if let rawValue = defaults.string(forKey: Self.appearanceModeKey),
           let mode = AppearanceMode(rawValue: rawValue) {
            self.appearanceMode = mode
            applyAppearanceMode(mode)
        }
    }

    /// Save notification preferences to UserDefaults
    private func saveNotificationPreferences() {
        if let data = try? JSONEncoder().encode(notificationPreferences) {
            UserDefaults.standard.set(data, forKey: Self.notificationPreferencesKey)
        }
    }

    /// Save privacy settings to UserDefaults
    private func savePrivacySettings() {
        if let data = try? JSONEncoder().encode(privacySettings) {
            UserDefaults.standard.set(data, forKey: Self.privacySettingsKey)
        }
    }

    /// Save appearance mode to UserDefaults
    private func saveAppearanceMode() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.appearanceModeKey)
    }

    // MARK: - Actions

    /// Load settings data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Load persisted user preferences from UserDefaults
        loadPersistedSettings()

        // Small delay for UI feedback
        try? await Task.sleep(for: .milliseconds(100))

        isLoading = false
    }

    /// Refresh data
    func refresh() async {
        await loadData()
    }

    /// Update profile
    func updateProfile(_ updatedProfile: SettingsProfileData) {
        profile = updatedProfile
        // In production, persist to storage/backend
    }

    /// Update tax home address
    func updateTaxHomeAddress(_ address: TaxHomeAddress) {
        taxHomeAddress = address
        // In production, persist to storage/backend
    }

    /// Toggle notification setting
    func toggleNotification(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) {
        notificationPreferences[keyPath: keyPath].toggle()
        saveNotificationPreferences()
    }

    /// Toggle privacy setting
    func togglePrivacy(_ keyPath: WritableKeyPath<PrivacySettings, Bool>) {
        privacySettings[keyPath: keyPath].toggle()
        savePrivacySettings()
    }

    /// Set appearance mode
    func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        saveAppearanceMode()
        applyAppearanceMode(mode)
    }

    /// Apply appearance mode to the app
    private func applyAppearanceMode(_ mode: AppearanceMode) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        switch mode {
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        }
    }

    /// Export user data
    func exportData() async -> URL? {
        isLoading = true

        // Simulate data export
        try? await Task.sleep(for: .seconds(1))

        // In production, would generate and return actual data export file
        isLoading = false
        return nil
    }

    /// Sign out
    func signOut() {
        // In production, clear user session and navigate to login
    }

    /// Delete account
    func deleteAccount() async {
        isLoading = true

        // Simulate account deletion
        try? await Task.sleep(for: .seconds(1))

        // In production, would call backend to delete account
        isLoading = false
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }

    /// Contact support via email
    func contactSupport() {
        let subject = "TravelNurse App Support Request"
        let body = """

        ---
        App Version: \(appVersion)
        Device: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        """

        // URL encode the subject and body
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let mailtoString = "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        guard let url = URL(string: mailtoString) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback: Show error that email is not configured
            errorMessage = "Unable to open email. Please ensure a mail app is configured on your device."
            showError = true
        }
    }

    /// Rate app via App Store review prompt
    func rateApp() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: windowScene)
    }
}

// MARK: - Preview Helper

extension SettingsViewModel {
    static var preview: SettingsViewModel {
        SettingsViewModel()
    }
}

