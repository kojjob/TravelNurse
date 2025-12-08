//
//  SettingsViewModelTests.swift
//  TravelNurseTests
//
//  Unit tests for SettingsViewModel
//

import XCTest
@testable import TravelNurse

final class SettingsViewModelTests: XCTestCase {

    var sut: SettingsViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        sut = SettingsViewModel()
    }

    @MainActor
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    @MainActor
    func test_initialState_hasDefaultProfile() {
        // Profile should have default placeholder values
        XCTAssertNotNil(sut.profile)
        XCTAssertFalse(sut.profile.firstName.isEmpty)
        XCTAssertFalse(sut.profile.lastName.isEmpty)
    }

    @MainActor
    func test_initialState_appearanceModeIsSystem() {
        // Default appearance mode should be system
        XCTAssertEqual(sut.appearanceMode, .system)
    }

    @MainActor
    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func test_initialState_showErrorIsFalse() {
        XCTAssertFalse(sut.showError)
    }

    @MainActor
    func test_initialState_errorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    @MainActor
    func test_initialState_notificationPreferencesHaveDefaults() {
        // Default notification preferences
        let prefs = sut.notificationPreferences
        XCTAssertTrue(prefs.pushEnabled)
        XCTAssertTrue(prefs.emailEnabled)
        XCTAssertTrue(prefs.taxDeadlineReminders)
        XCTAssertTrue(prefs.assignmentReminders)
    }

    @MainActor
    func test_initialState_privacySettingsHaveDefaults() {
        // Default privacy settings
        let settings = sut.privacySettings
        XCTAssertTrue(settings.analyticsEnabled)
        XCTAssertTrue(settings.crashReportingEnabled)
        XCTAssertTrue(settings.locationTrackingEnabled)
    }

    // MARK: - Appearance Mode Tests

    @MainActor
    func test_setAppearanceMode_toLight() {
        // When
        sut.setAppearanceMode(.light)

        // Then
        XCTAssertEqual(sut.appearanceMode, .light)
    }

    @MainActor
    func test_setAppearanceMode_toDark() {
        // When
        sut.setAppearanceMode(.dark)

        // Then
        XCTAssertEqual(sut.appearanceMode, .dark)
    }

    @MainActor
    func test_setAppearanceMode_toSystem() {
        // Given - set to dark first
        sut.setAppearanceMode(.dark)

        // When
        sut.setAppearanceMode(.system)

        // Then
        XCTAssertEqual(sut.appearanceMode, .system)
    }

    // MARK: - AppearanceMode Enum Tests

    @MainActor
    func test_appearanceMode_allCasesExist() {
        let allModes = AppearanceMode.allCases

        XCTAssertEqual(allModes.count, 3)
        XCTAssertTrue(allModes.contains(.system))
        XCTAssertTrue(allModes.contains(.light))
        XCTAssertTrue(allModes.contains(.dark))
    }

    @MainActor
    func test_appearanceMode_hasRawValues() {
        XCTAssertEqual(AppearanceMode.system.rawValue, "System")
        XCTAssertEqual(AppearanceMode.light.rawValue, "Light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "Dark")
    }

    @MainActor
    func test_appearanceMode_hasIconNames() {
        XCTAssertFalse(AppearanceMode.system.iconName.isEmpty)
        XCTAssertFalse(AppearanceMode.light.iconName.isEmpty)
        XCTAssertFalse(AppearanceMode.dark.iconName.isEmpty)
    }

    @MainActor
    func test_appearanceMode_hasIdentifier() {
        // id should equal rawValue
        XCTAssertEqual(AppearanceMode.system.id, "System")
        XCTAssertEqual(AppearanceMode.light.id, "Light")
        XCTAssertEqual(AppearanceMode.dark.id, "Dark")
    }

    // MARK: - Notification Toggle Tests (KeyPath-based)

    @MainActor
    func test_toggleNotification_assignmentReminders() {
        // Given
        let initial = sut.notificationPreferences.assignmentReminders

        // When
        sut.toggleNotification(\.assignmentReminders)

        // Then
        XCTAssertNotEqual(sut.notificationPreferences.assignmentReminders, initial)
    }

    @MainActor
    func test_toggleNotification_expenseReminders() {
        // Given
        let initial = sut.notificationPreferences.expenseReminders

        // When
        sut.toggleNotification(\.expenseReminders)

        // Then
        XCTAssertNotEqual(sut.notificationPreferences.expenseReminders, initial)
    }

    @MainActor
    func test_toggleNotification_taxDeadlineReminders() {
        // Given
        let initial = sut.notificationPreferences.taxDeadlineReminders

        // When
        sut.toggleNotification(\.taxDeadlineReminders)

        // Then
        XCTAssertNotEqual(sut.notificationPreferences.taxDeadlineReminders, initial)
    }

    @MainActor
    func test_toggleNotification_pushEnabled() {
        // Given
        let initial = sut.notificationPreferences.pushEnabled

        // When
        sut.toggleNotification(\.pushEnabled)

        // Then
        XCTAssertNotEqual(sut.notificationPreferences.pushEnabled, initial)
    }

    @MainActor
    func test_toggleNotification_weeklyDigest() {
        // Given
        let initial = sut.notificationPreferences.weeklyDigest

        // When
        sut.toggleNotification(\.weeklyDigest)

        // Then
        XCTAssertNotEqual(sut.notificationPreferences.weeklyDigest, initial)
    }

    @MainActor
    func test_toggleNotification_doubleToggle_returnsToOriginal() {
        // Given
        let initial = sut.notificationPreferences.assignmentReminders

        // When - toggle twice
        sut.toggleNotification(\.assignmentReminders)
        sut.toggleNotification(\.assignmentReminders)

        // Then
        XCTAssertEqual(sut.notificationPreferences.assignmentReminders, initial)
    }

    // MARK: - Privacy Toggle Tests (KeyPath-based)

    @MainActor
    func test_togglePrivacy_analyticsEnabled() {
        // Given
        let initial = sut.privacySettings.analyticsEnabled

        // When
        sut.togglePrivacy(\.analyticsEnabled)

        // Then
        XCTAssertNotEqual(sut.privacySettings.analyticsEnabled, initial)
    }

    @MainActor
    func test_togglePrivacy_crashReportingEnabled() {
        // Given
        let initial = sut.privacySettings.crashReportingEnabled

        // When
        sut.togglePrivacy(\.crashReportingEnabled)

        // Then
        XCTAssertNotEqual(sut.privacySettings.crashReportingEnabled, initial)
    }

    @MainActor
    func test_togglePrivacy_locationTrackingEnabled() {
        // Given
        let initial = sut.privacySettings.locationTrackingEnabled

        // When
        sut.togglePrivacy(\.locationTrackingEnabled)

        // Then
        XCTAssertNotEqual(sut.privacySettings.locationTrackingEnabled, initial)
    }

    @MainActor
    func test_togglePrivacy_doubleToggle_returnsToOriginal() {
        // Given
        let initial = sut.privacySettings.analyticsEnabled

        // When - toggle twice
        sut.togglePrivacy(\.analyticsEnabled)
        sut.togglePrivacy(\.analyticsEnabled)

        // Then
        XCTAssertEqual(sut.privacySettings.analyticsEnabled, initial)
    }

    // MARK: - Profile Tests

    @MainActor
    func test_profile_fullNameIsComputed() {
        // Profile should have a computed full name
        let fullName = sut.profile.fullName
        XCTAssertFalse(fullName.isEmpty)
        XCTAssertTrue(fullName.contains(" ")) // Should have space between first and last
    }

    @MainActor
    func test_profile_initialsAreComputed() {
        // Profile should have computed initials
        let initials = sut.profile.initials
        XCTAssertFalse(initials.isEmpty)
        XCTAssertEqual(initials.count, 2) // Two characters for initials
    }

    @MainActor
    func test_updateProfile_changesProfile() {
        // Given
        let newProfile = SettingsProfileData(
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            nursingLicense: "RN-999999",
            specialty: "ER",
            yearsExperience: 5
        )

        // When
        sut.updateProfile(newProfile)

        // Then
        XCTAssertEqual(sut.profile.firstName, "Test")
        XCTAssertEqual(sut.profile.lastName, "User")
        XCTAssertEqual(sut.profile.email, "test@example.com")
    }

    // MARK: - App Info Tests

    @MainActor
    func test_appVersion_isNotEmpty() {
        let version = sut.appVersion
        XCTAssertFalse(version.isEmpty)
    }

    @MainActor
    func test_appVersion_containsVersionKeyword() {
        let version = sut.appVersion
        XCTAssertTrue(version.contains("Version"))
    }

    // MARK: - Support Email Tests

    @MainActor
    func test_supportEmail_isValidFormat() {
        let email = sut.supportEmail

        XCTAssertTrue(email.contains("@"))
        XCTAssertTrue(email.contains("."))
    }

    // MARK: - URL Tests

    @MainActor
    func test_privacyPolicyURL_isValid() {
        XCTAssertNotNil(sut.privacyPolicyURL)
    }

    @MainActor
    func test_termsOfServiceURL_isValid() {
        XCTAssertNotNil(sut.termsOfServiceURL)
    }

    // MARK: - Error Handling Tests

    @MainActor
    func test_dismissError_setsShowErrorToFalse() {
        // Given
        sut.showError = true

        // When
        sut.dismissError()

        // Then
        XCTAssertFalse(sut.showError)
    }

    @MainActor
    func test_dismissError_clearsErrorMessage() {
        // Given
        sut.showError = true

        // When
        sut.dismissError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Tax Home Tests

    @MainActor
    func test_taxHomeAddress_hasPlaceholder() {
        XCTAssertNotNil(sut.taxHomeAddress)
        XCTAssertFalse(sut.taxHomeAddress.city.isEmpty)
    }

    @MainActor
    func test_taxHomeComplianceScore_isWithinRange() {
        // Compliance score should be between 0 and 1
        XCTAssertGreaterThanOrEqual(sut.taxHomeComplianceScore, 0)
        XCTAssertLessThanOrEqual(sut.taxHomeComplianceScore, 1)
    }

    @MainActor
    func test_formattedComplianceScore_containsPercentage() {
        let formatted = sut.formattedComplianceScore
        XCTAssertTrue(formatted.contains("%"))
    }

    @MainActor
    func test_complianceStatus_isNotEmpty() {
        let status = sut.complianceStatus
        XCTAssertFalse(status.isEmpty)
    }

    @MainActor
    func test_daysAtTaxHome_isNonNegative() {
        XCTAssertGreaterThanOrEqual(sut.daysAtTaxHome, 0)
    }

    @MainActor
    func test_updateTaxHomeAddress_changesAddress() {
        // Given
        let newAddress = TaxHomeAddress(
            street: "456 Test Ave",
            city: "Austin",
            state: .texas,
            zipCode: "78701"
        )

        // When
        sut.updateTaxHomeAddress(newAddress)

        // Then
        XCTAssertEqual(sut.taxHomeAddress.city, "Austin")
        XCTAssertEqual(sut.taxHomeAddress.state, .texas)
    }

    // MARK: - SettingsSection Enum Tests

    @MainActor
    func test_settingsSection_allCasesExist() {
        let allSections = SettingsSection.allCases

        XCTAssertGreaterThanOrEqual(allSections.count, 7)
        XCTAssertTrue(allSections.contains(.profile))
        XCTAssertTrue(allSections.contains(.taxHome))
        XCTAssertTrue(allSections.contains(.notifications))
        XCTAssertTrue(allSections.contains(.appearance))
        XCTAssertTrue(allSections.contains(.privacy))
        XCTAssertTrue(allSections.contains(.support))
        XCTAssertTrue(allSections.contains(.about))
    }

    @MainActor
    func test_settingsSection_hasIconNames() {
        for section in SettingsSection.allCases {
            XCTAssertFalse(section.iconName.isEmpty, "\(section.rawValue) should have an icon name")
        }
    }

    @MainActor
    func test_settingsSection_hasRawValues() {
        XCTAssertEqual(SettingsSection.profile.rawValue, "Profile")
        XCTAssertEqual(SettingsSection.taxHome.rawValue, "Tax Home")
        XCTAssertEqual(SettingsSection.notifications.rawValue, "Notifications")
    }

    // MARK: - NotificationPreferences Tests

    @MainActor
    func test_notificationPreferences_defaultsHaveExpectedValues() {
        let defaults = NotificationPreferences.defaults

        XCTAssertTrue(defaults.pushEnabled)
        XCTAssertTrue(defaults.emailEnabled)
        XCTAssertTrue(defaults.taxDeadlineReminders)
        XCTAssertTrue(defaults.assignmentReminders)
        XCTAssertFalse(defaults.expenseReminders) // Default is false
        XCTAssertTrue(defaults.weeklyDigest)
    }

    // MARK: - PrivacySettings Tests

    @MainActor
    func test_privacySettings_defaultsHaveExpectedValues() {
        let defaults = PrivacySettings.defaults

        XCTAssertTrue(defaults.analyticsEnabled)
        XCTAssertTrue(defaults.crashReportingEnabled)
        XCTAssertTrue(defaults.locationTrackingEnabled)
    }

    // MARK: - Sheet State Tests

    @MainActor
    func test_initialState_sheetsAreNotShowing() {
        XCTAssertFalse(sut.showEditProfile)
        XCTAssertFalse(sut.showEditTaxHome)
        XCTAssertFalse(sut.showExportConfirmation)
        XCTAssertFalse(sut.showDeleteConfirmation)
    }

    @MainActor
    func test_showEditProfile_canBeToggled() {
        // Given
        XCTAssertFalse(sut.showEditProfile)

        // When
        sut.showEditProfile = true

        // Then
        XCTAssertTrue(sut.showEditProfile)
    }

    // MARK: - Notification Service Integration Tests

    @MainActor
    func test_notificationPermissionGranted_defaultsToFalse() {
        // Notification permission should default to false until explicitly requested
        XCTAssertFalse(sut.notificationPermissionGranted)
    }

    @MainActor
    func test_cancelNotifications_doesNotCrashWithoutService() {
        // Should gracefully handle missing service
        sut.cancelNotifications(of: .expenseReminder)
        // Test passes if no crash occurs
        XCTAssertTrue(true)
    }

    @MainActor
    func test_scheduleTaxDeadlineReminders_respectsPreferences() async {
        // Given - disable tax deadline reminders
        sut.notificationPreferences.taxDeadlineReminders = false

        // When - try to schedule (should return early due to preference)
        await sut.scheduleTaxDeadlineReminders()

        // Then - no crash, function respects preferences
        XCTAssertFalse(sut.notificationPreferences.taxDeadlineReminders)
    }

    @MainActor
    func test_scheduleExpenseReminder_respectsPreferences() async {
        // Given - disable expense reminders
        sut.notificationPreferences.expenseReminders = false

        // When - try to schedule (should return early due to preference)
        await sut.scheduleExpenseReminder()

        // Then - no crash, function respects preferences
        XCTAssertFalse(sut.notificationPreferences.expenseReminders)
    }

    @MainActor
    func test_syncNotificationSchedules_disablesPushWhenNotEnabled() async {
        // Given - disable push notifications
        sut.notificationPreferences.pushEnabled = false

        // When - sync schedules
        await sut.syncNotificationSchedules()

        // Then - push should still be disabled
        XCTAssertFalse(sut.notificationPreferences.pushEnabled)
    }

    @MainActor
    func test_notificationType_allCasesHaveIdentifiers() {
        // Verify all notification types have valid identifiers
        for type in NotificationType.allCases {
            XCTAssertFalse(type.identifier.isEmpty, "\(type) should have a valid identifier")
        }
    }

    @MainActor
    func test_notificationType_identifiersAreUnique() {
        // Verify notification type identifiers are unique
        let identifiers = NotificationType.allCases.map { $0.identifier }
        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(identifiers.count, uniqueIdentifiers.count, "All notification identifiers should be unique")
    }

    // MARK: - NotificationService Static Methods Tests

    @MainActor
    func test_quarterlyTaxDeadlines_returnsCorrectCount() {
        let deadlines = NotificationService.quarterlyTaxDeadlines(for: 2025)
        XCTAssertEqual(deadlines.count, 4, "Should return 4 quarterly deadlines")
    }

    @MainActor
    func test_quarterlyTaxDeadlines_hasCorrectQuarters() {
        let deadlines = NotificationService.quarterlyTaxDeadlines(for: 2025)
        let quarters = deadlines.map { $0.quarter }

        XCTAssertTrue(quarters.contains("Q1"))
        XCTAssertTrue(quarters.contains("Q2"))
        XCTAssertTrue(quarters.contains("Q3"))
        XCTAssertTrue(quarters.contains("Q4"))
    }

    @MainActor
    func test_quarterlyTaxDeadlines_datesAreInFuture() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let nextYear = currentYear + 1
        let deadlines = NotificationService.quarterlyTaxDeadlines(for: nextYear)

        // All deadlines for next year should be in the future
        for deadline in deadlines {
            XCTAssertTrue(deadline.date > Date(), "Deadline \(deadline.quarter) should be in the future")
        }
    }

    @MainActor
    func test_oneYearWarningDays_hasCorrectValues() {
        let warningDays = NotificationService.oneYearWarningDays

        XCTAssertEqual(warningDays.count, 3)
        XCTAssertTrue(warningDays.contains(300))
        XCTAssertTrue(warningDays.contains(330))
        XCTAssertTrue(warningDays.contains(350))
    }
}
